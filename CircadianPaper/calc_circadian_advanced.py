# Import statements
import pandas as pd
import datetime as datetime
import numpy as np 
import matlab.engine
import statsmodels.api as sm
import matplotlib.pyplot as plt
from sklearn.metrics import r2_score
from statsmodels.tsa.ar_model import ar_select_order
from sklearn.model_selection import KFold
from statistics import mean
from datetime import timedelta
import torch
from torch import nn, optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score
import scipy.stats as st 
from collections import defaultdict

# Start MATLAB engine
eng = matlab.engine.start_matlab()

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Constants and Utility Functions
L1_LAMBDA = 1e-5
LABEL_MAPPING = {0: 0, 2: 0, 3: 1}
TIME_INDEX = [datetime.time(i // 60, i % 60) for i in range(0, 1440, 10)]

def load_mat_data(mat_file: str, pt_id: int, hemi: int):
    """
    Load LFP and entropy data from a MATLAB .mat file for a given patient and hemisphere in VC/VS.
    
    Parameters:
    - mat_file (str): Path to the .mat file containing the data.
    - pt_id (int): The patient identifier.
    - hemi (int): Hemisphere indentifier (0 for left hemisphere, 1 for right hemisphere).
    
    Returns:
    - tuple: A tuple containing two pandas DataFrames. The first DataFrame contains LFP data, and the second contains entropy data.
    
    Note:
    This function requires the MATLAB Engine API for Python to run MATLAB commands from Python.
    """
    
    # Lambda function to create MATLAB command for loading specific patient and hemisphere data
    command = lambda x: f"load('{mat_file}').percept_data.{x}{{{pt_id},{2+hemi}}};"
    
    # Load LFP data into DataFrame
    df = pd.DataFrame(eng.eval(command("LFP_filled_matrix")), index=TIME_INDEX,
                      columns=eng.eval(command("days"))[0])
    
    # Load entropy data into DataFrame
    se_df = pd.DataFrame(eng.eval(command("entropy")), index=['SE'],
                         columns=eng.eval(command("days"))[0])
    
    return df, se_df

def get_state_labels(mat_file: str, pt_id: int, master_df: pd.DataFrame):
    """
    Retrieves state labels for each data point in a dataset based on a MATLAB file.
    
    This function assigns labels to data points representing different states such as hypomania,
    non_responder, and responder, based on their occurrence dates. 
    
    Parameters:
    - mat_file (str): Path to the MATLAB file containing state information.
    - pt_id (int): Patient identifier
    - master_df (pd.DataFrame): DataFrame containing the dates for which state labels are needed.
    
    Returns:
    - numpy.ndarray: An array of state labels for each column in master_df.
    """
    
    # Initialize state labels array with `inf` to indicate unidentified states initially.
    state_label = np.full(master_df.shape[1], np.inf)

    # Pre-assign '0' for the pre-DBS period.
    state_label[[i for i, date in enumerate(master_df.columns) if date.days < 0]] = 0

    # Loop through each state defined in the MATLAB file and assign labels accordingly.
    for label, state in enumerate(['hypomania', 'non_responder', 'responder']):
        # Extract days corresponding to each state from the MATLAB file.
        state_days = eng.eval(f"load('{mat_file}').zone_index.{state}{{{pt_id},1}};")
        # Assign labels to the dates matching the extracted days.
        state_label[[i for i, date in enumerate(master_df.columns) if date.days in np.array(state_days)]] = label + 1

    # Replace `inf` labels with '4' for any data points that remain unlabeled.
    state_label = np.where(state_label == np.inf, 4, state_label)
    
    return state_label

def contig_data(days: list):
    """
    Splits a list of days into indices indicating the start of new contiguous sequences based on day continuity.
    
    Parameters:
    - days (list of int): A list of days.
    
    Returns:
    - list of int: Indices indicating the start of each new contiguous sequence within the days list.
    """
    
    contig = [0]
    
    # Find indices where a new contiguous sequence starts due to a gap in the days.
    # A gap is identified when the difference between consecutive days is more than 1.
    contig.extend([x+1 for x in range(len(days)-1) if days[x+1] != days[x] + 1 ])
    
    contig.append(len(days))
    
    return contig

def query_time(value: timedelta):
    """
    Converts a timedelta object into a tuple representing a specific time and day count.
    
    Parameters:
    - value (timedelta): A timedelta object representing the duration from a starting point.
    
    Returns:
    - tuple: A tuple of (time, days), where 'time' is the time within a given day
             and 'days' represents the total number of days in the timedelta.
    """
    
    # Convert the total seconds in the timedelta to an index based on 10-minute intervals.
    row = int(value.seconds / 600)  # 600 seconds = 10 minutes
    
    # Return a tuple of (time, days), where 'time' is the time within a given day.
    return (TIME_INDEX[row], value.days)

def find_common_lags(folds: list, threshold: int):
    """
    Identifies elements that are common across multiple folds, based on a specified frequency threshold.
    
    Parameters:
    - folds (list of arrays): A list containing folds from which to find common elements.
    - threshold (int): The minimum number of folds in which an element must appear to be considered common.
    
    Returns:
    - set: A set of elements that appear in at least 'threshold' number of folds.
    """
    
    # Initialize a defaultdict to count occurrences of each unique element across all folds.
    lag_counts = defaultdict(int)
    
    # Count each unique element's frequency across all provided folds.
    for fold in folds:
        unique_lags = np.unique(fold)
        for lag in unique_lags:
            lag_counts[lag] += 1
            
    # Filter elements that meet or exceed the frequency threshold.        
    common_lags = {k for k, v in lag_counts.items() if v >= threshold}
    
    return common_lags

def create_nn(input_size: int, hidden_size1: int, output_size: int):
    """
    Defines and returns a simple neural network architecture with a single hidden layer.
    
    Parameters:
    - input_size (int): Size of the input layer (number of input features).
    - hidden_size1 (int): Size of the hidden layer.
    - output_size (int): Size of the output layer (number of output features or classes).
    
    Returns:
    - Instance of NeuralNetwork: A PyTorch neural network model.
    """
    
    class NeuralNetwork(nn.Module):
        def __init__(self):
            super(NeuralNetwork, self).__init__()
            # Linear layer from input to hidden and hidden to output, with ReLU activation in between.
            self.layer1 = nn.Linear(input_size, hidden_size1)
            self.relu = nn.ReLU()
            self.layer2 = nn.Linear(hidden_size1, output_size)

        def forward(self, x):
            # Forward pass: input -> linear -> ReLU -> linear -> output
            x = self.layer1(x)
            x = self.relu(x)
            x = self.layer2(x)
            return x

    return NeuralNetwork()

def create_dataloader(X_df: pd.DataFrame, y_df: pd.DataFrame, batch_size: int=64, shuffle: bool=True):
    """
    Creates a PyTorch DataLoader for training or evaluation from pandas DataFrames.
    
    Parameters:
    - X_df (pd.DataFrame): DataFrame containing the input features.
    - y_df (pd.DataFrame): DataFrame containing the labels.
    - batch_size (int, optional): Size of each data batch. Defaults to 64.
    - shuffle (bool, optional): Whether to shuffle the data every epoch. Defaults to True.
    
    Returns:
    - DataLoader: A PyTorch DataLoader containing the dataset for training or evaluation.
    """
    
    # Conversion of pandas DataFrames to numpy arrays and then to PyTorch tensors.
    X = X_df.values.T  # Transpose to match expected input dimensions for PyTorch models.
    y = y_df.values
    X_tensor = torch.tensor(X, dtype=torch.float32)
    y_tensor = torch.tensor(y, dtype=torch.float32)

    # Creation of TensorDataset and DataLoader for efficient data handling.
    dataset = TensorDataset(X_tensor, y_tensor)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=shuffle)

    return dataloader

def train_model(model, criterion, optimizer, train_loader: DataLoader, test_loader: DataLoader, epochs: int=50, l1_lambda: float=1e-5):
    """
    Train and evaluate a neural network model using provided data loaders, loss criterion, and optimizer.
    
    Parameters:
    - model: The neural network model to train.
    - criterion: The loss function used to evaluate the model's performance.
    - optimizer: The optimization algorithm used to update model weights.
    - train_loader: DataLoader containing the training dataset.
    - test_loader: DataLoader containing the test dataset.
    - epochs (int, optional): Number of training epochs. Defaults to 50.
    - l1_lambda (float, optional): Coefficient for L1 regularization. Defaults to 1e-5.
    
    Returns:
    - dict: A dictionary containing training and testing losses and R^2 scores across epochs,
            as well as the best test R^2 score and corresponding predictions.
    """
    
    # Tracking performance metrics across epochs
    train_losses, test_losses, train_r2, test_r2 = [], [], [], []
    best_r2 = float('-inf')  # Initialize the best R^2 score

    for epoch in range(epochs):
        # Training and evaluation phases
        model.train()  # Set model to training mode
        running_loss, running_test_loss = 0.0, 0.0  # Track losses
        # Accumulators for actual and predicted values to compute R^2 score
        train_act, train_pred, test_act, test_pred = [], [], [], []

        # Loop over training batches
        for inputs, targets in train_loader:
            inputs, targets = inputs.to(device), targets.to(device)  # Move data to the device
            optimizer.zero_grad()  # Reset gradients
            
            predictions = model(inputs).squeeze()  # Forward pass
            loss = criterion(predictions, targets)  # Compute loss
            
            l1_penalty = sum(p.abs().sum() for p in model.parameters())  # L1 regularization penalty
            total_loss = loss + (l1_lambda * l1_penalty)  # Total loss with regularization
            
            total_loss.backward()  # Backpropagation
            optimizer.step()  # Update model parameters

            # Update training metrics
            running_loss += total_loss.item() * inputs.size(0)
            train_act.extend(targets.tolist())
            train_pred.extend(predictions.tolist())

        # Evaluation phase
        model.eval()  # Set model to evaluation mode
        with torch.no_grad():  # Disable gradient computation
            for inputs, targets in test_loader:
                inputs, targets = inputs.to(device), targets.to(device)
                predictions = model(inputs).squeeze()
                loss = criterion(predictions, targets)  # Compute loss

                # Update test metrics
                running_test_loss += loss.item() * inputs.size(0)
                test_act.extend(targets.tolist())
                test_pred.extend(predictions.tolist())

        # Compute average losses and R^2 scores for the epoch
        epoch_train_loss = running_loss / len(train_loader.dataset)
        epoch_test_loss = running_test_loss / len(test_loader.dataset)
        epoch_train_r2 = r2_score(train_act, train_pred)
        epoch_test_r2 = r2_score(test_act, test_pred)

        # Update best test R^2 score and predictions
        if epoch_test_r2 > best_r2:
            best_r2 = epoch_test_r2
            best_preds = (test_act, test_pred)

        # Record metrics for the epoch
        train_losses.append(epoch_train_loss)
        test_losses.append(epoch_test_loss)
        train_r2.append(epoch_train_r2)
        test_r2.append(epoch_test_r2)

        # Output training progress
        print(f"Epoch {epoch+1}/{epochs}: Train loss = {epoch_train_loss:.4f}, Train R^2 = {epoch_train_r2:.4f}, Test loss = {epoch_test_loss:.4f}, Test R^2 = {epoch_test_r2:.4f}")

    # Return a dictionary of tracked metrics and best results
    return {
        'train_losses': train_losses,
        'test_losses': test_losses,
        'train_r2': train_r2,
        'test_r2': test_r2,
        'best_test_r2': best_r2,
        'best_predictions': best_preds
    }

def run_regression(master_df: pd.DataFrame, lag_terms: list):
    """
    Performs regression analysis on a dataset with time lags to identify significant predictors.
    
    Utilizes K-Fold cross-validation to assess the performance and significance of lagged terms in
    predicting a target variable. 
    
    Parameters:
    - master_df (pd.DataFrame): DataFrame containing the original data and its lagged terms.
    - lag_terms (list of str): A list of variable names that represent lag terms.
    
    Returns:
    - tuple: A tuple containing the common significant lags across folds, the final regression model,
             and a continuity flag indicating if all final model terms are significant.
    """
    
    # Initialize KFold cross-validator
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    r2_scores = []  # List to hold R^2 scores for each fold
    significant_lags_per_fold = []  # List to track significant lags identified in each fold

    # Iterate over each fold
    for train_index, test_index in kf.split(master_df.T):
        # Split data into training and testing sets based on current fold
        train, test = master_df.iloc[:, train_index], master_df.iloc[:, test_index]
        
        # Fit OLS regression model on the training set
        model = sm.OLS(train.loc['Original Data'], train.loc[lag_terms].T).fit()
        
        # Identify significant lags (p < 0.01) in the current fold
        significant_lags = model.pvalues[model.pvalues < 0.01].index.tolist()
        significant_lags_per_fold.append(significant_lags)
        
        # Make predictions on the test set and compute R^2 score
        predictions = model.predict(test.loc[lag_terms].T)
        r2_scores.append(r2_score(test.loc['Original Data'], predictions))
    
    # Find common lags that are significant across folds
    common_lags = list(find_common_lags(significant_lags_per_fold, 3)) + ['constant']
    
    # Fit a final model using common significant lags
    final_model = sm.OLS(master_df.loc['Original Data'], master_df.loc[common_lags].T).fit()
    
    # Determine if all terms in the final model are significant
    cont = 0 if (final_model.pvalues < 0.05).sum() >= len(final_model.pvalues) - 1 else 1
    
    return common_lags, final_model, cont

def perform_logistic_regression(data: pd.DataFrame):
    """
    Performs logistic regression using Leave-One-Patient-Out Cross-Validation (LOPO-CV) to evaluate model performance.
    
    
    Parameters:
    - data (pandas.DataFrame): Dataframe containing the R2, dR2, y-label, and patient id for a given metric. 
    
    Returns:
    - tuple of lists: 
        - True labels for each sample.
        - Predicted probabilities of the positive class for each sample.
        - Predicted classes for each sample.
    """
    # Lists to store true labels, predicted probabilities, and predicted classes.
    true, pred, pred_rd = [], [], []
    
    # Iterate over each patient split.
    for pt in set(data['PT']):
        
        # Split the data into training and testing sets.
        test_data = data.loc[data['PT'] == pt]
        train_data = data.loc[data['PT'] != pt]
 
        # Reshape test data to ensure it has the correct dimensions.
        test_x = test_data.iloc[:,:-2].values.reshape(-1,1)
        test_y = test_data.iloc[:,-2].values

        # Reshape train data to ensure it has the correct dimensions.
        train_x = train_data.iloc[:,:-2].values.reshape(-1,1)
        
        train_y = train_data.iloc[:,-2].values

        # Train the logistic regression model.
        clf = LogisticRegression(class_weight='balanced', penalty = None).fit(train_x, train_y)
        
        # Extend the lists with the test outcomes and predictions.   
        true.extend(test_y)
        pred.extend(clf.predict_proba(test_x)[:,1]) # Probability of the positive class.
        pred_rd.extend(clf.predict(test_x)) # Predicted class labels.

    return true, pred, pred_rd
    
def circular_shift(data: pd.DataFrame):
    """
    Applies a circular shift to the 'Y' column for each patient within the dataset, 
    with the shift magnitude randomly determined for each patient.

    Parameters:
    - data (pd.DataFrame): The DataFrame containing the dataset. Must include a 'PT' column 
                           for patient IDs and a 'Y' column for the values to be shifted.

    Returns:
    - data (pd.DataFrame): The modified DataFrame with the 'Y' values circularly shifted 
                           for each patient.
    """
    
    # Initialize an empty list to store the circularly shifted 'Y' values for all patients.
    roll_y = []
    
    # Iterate through each unique patient ID.
    for pt in data.loc[:,'PT'].unique():
        # Extract 'Y' values for the current patient as a numpy array.
        pt_y = data.loc[data['PT'] == pt,'Y'].to_numpy()
        # Append the circularly shifted 'Y' array to the list, shifting by a random magnitude.
        roll_y.append(np.roll(pt_y, random.randrange(0,pt_y.shape[0])))
        
    # Update the 'Y' column in the original DataFrame with the concatenated shifted arrays.
    data.loc[:, 'Y'] = np.concatenate(roll_y)
    
    # Return the modified DataFrame.
    return data
    
def NN_AR(train: pd.DataFrame, test: pd.DataFrame, index: list):
    """
    Trains a neural network on autoregressive features and evaluates the model's predictive accuracy on test data based on the R-squared metric.
    
    Parameters:
    - train (pd.DataFrame): DataFrame containing the training data with autoregressive features and the target series.
    - test (pd.DataFrame): DataFrame containing the test data with the same autoregressive features and the target series.
    - index (list): List of column names or indices representing the autoregressive features in the data.
    
    Returns:
    - float: The best R-squared value achieved by the model on the test dataset.
    - list: Predictions made by the model on the test dataset.
    """

    # Create a neural network model with specified architecture.
    model = create_nn(input_size=len(index), hidden_size1=32, output_size=1)
    
    # Prepare DataLoader objects for both training and test datasets.
    train_loader = create_dataloader(train.loc[index, :], train.loc['Original Data', :])
    test_loader = create_dataloader(test.loc[index, :], test.loc['Original Data', :], shuffle=False)

    # Set the loss function and optimizer for model training.
    criterion = nn.L1Loss()  # L1 loss is used here, which is robust to outliers.
    optimizer = optim.Adam(model.parameters(), lr=0.001)  # Adam optimizer with a learning rate of 0.001.
    
    # Train the model and retrieve performance metrics.
    metrics = train_model(model, criterion, optimizer, train_loader, test_loader, epochs=50, l1_lambda=L1_LAMBDA)
    best_test_r2 = metrics['best_test_r2']  # Best R-squared value on the test data.
    preds = metrics['best_predictions']  # Predictions corresponding to the best R-squared value.

    return best_test_r2, preds

def linAR(train: pd.DataFrame, test: pd.DataFrame, sig_index: list):
    """
    Performs linear regression on training data using significant autoregressive terms and evaluates the model's predictive accuracy on test data based on the R-squared metric.

    
    Parameters:
    - train (pd.DataFrame): DataFrame containing the training data, including the target variable and autoregressive terms.
    - test (pd.DataFrame): DataFrame containing the test data with the same structure as the training data.
    - sig_index (list): Indices or column names of the autoregressive features considered significant.
    
    Returns:
    - float: R-squared value indicating the model's predictive accuracy on the test data.
    - list: A list of predictions made by the model on the test dataset.
    """
    
    # Fit the linear regression model using significant autoregressive terms from the training data.
    model = sm.OLS(train.loc['Original Data'], train.loc[sig_index].T).fit()
    
    # Generate predictions for the test data using the fitted model.
    predictions = model.predict(test.loc[sig_index].T)

    # Calculate the R-squared value to evaluate model performance on the test data.
    r2 = r2_score(test.loc['Original Data'], predictions)
    
    return r2, predictions.tolist()

def cosinor(train: pd.DataFrame, test: pd.DataFrame, comp: int):
    """
    Fits a cosinor model to training data to capture rhythmic variations and evaluates its performance on test data using the R2 metric.

    Parameters:
    - train (pd.DataFrame): DataFrame containing the training data.
    - test (pd.DataFrame): DataFrame containing the test data.
    - comp (int): The number of harmonic components (sine and cosine pairs) to include in the model.
    
    Returns:
    - float: The R2 value, indicating the proportion of variance in the test data explained by the model.
    - list: Predictions made by the cosinor model on the test dataset.
    """
    
    # Define the explanatory variables for the cosinor model, including sine and cosine terms for each component, plus a constant term for the intercept.
    exogs = [f'rrr{i}' for i in range(1, comp + 1)] + [f'sss{i}' for i in range(1, comp + 1)] + ['constant']
    
    # Fit the Ordinary Least Squares (OLS) regression model to the training data using the specified explanatory variables.
    model = sm.OLS(train.loc['Original Data'], train.loc[exogs].T).fit()
    
    # Use the fitted model to make predictions on the test data.
    predictions = model.predict(test.loc[exogs].T)

    # Calculate the R-squared value to assess how well the model's predictions match the actual data.
    r2 = r2_score(test.loc['Original Data'], predictions)
    
    return r2, predictions.tolist()

def get_r2(gl: pd.DataFrame, r2_df: pd.DataFrame, state: str, pred_df: pd.DataFrame, df: pd.DataFrame, index: list=None, model: str='LinAR', comp: int=1):
    """
    Performs regression analysis with K-Fold cross-validation, computes R2 metrics, and aggregates predictions.
    
    This function supports three types of models: Linear Regression ('LinAR'), Neural Network ('NN_AR'), and Cosinor,
    chosen based on the 'model' parameter. 
    
    Parameters:
    - gl (pd.DataFrame): DataFrame containing the data to be analyzed, indexed by time.
    - r2_df (pd.DataFrame): DataFrame for storing R2 scores along with corresponding days and states.
    - state (str): The state associated with the data being analyzed.
    - pred_df (pd.DataFrame): DataFrame for storing predictions made by the model.
    - df (pd.DataFrame): DataFrame containing original data for comparison against predictions.
    - index (list, optional): List of indices representing features for the 'LinAR' and 'NN_AR' models.
    - model (str, optional): Specifies the model type ('LinAR', 'NN_AR', or 'Cosinor'). Defaults to 'LinAR'.
    - comp (int, optional): The number of components to use with the 'Cosinor' model. Defaults to 1.
    
    Returns:
    - pd.DataFrame: Updated r2_df sorted by day with R² scores for each day.
    - pd.DataFrame: Updated pred_df with aggregated predictions across K-Fold cross-validation.
    - list: List of R² scores obtained from each fold of the cross-validation process.
    """
    
    # Initialize KFold for cross-validation.
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    kfold_r2 = []  # List to store R² scores from each fold.

    # Iterate through each fold of the cross-validation.
    for i, (train_index, test_index) in enumerate(kf.split(gl.T)):
        # Split data into training and testing sets based on the fold.
        train = gl.iloc[:, train_index]
        test = gl.iloc[:, test_index]
        
        # Select and apply the specified model.
        if model == 'LinAR':
            r2, preds = linAR(train, test, index)  # Linear Regression
        elif model == 'NN_AR':
            r2, preds = NN_AR(train, test, index)  # Neural Network
        elif model == 'Cosinor':
            r2, preds = cosinor(train, test, comp)  # Cosinor model
        
        # Store predictions in pred_df.
        for x in range(len(preds)):
            ind = query_time(test.columns[x])  # Convert test index to time and day.
            pred_df.loc[ind[0], ind[1]] = preds[x]
        kfold_r2.append(r2)  # Store R² score for the fold.
    
    # Process data for each day to compute day-specific R² scores.
    days = list(set([x.days for x in gl.columns]))  # Unique days in the dataset.
    
    for test_day in days:
        # Extract original and predicted data for the day.
        orig = df.loc[:, test_day]
        pred = pred_df.loc[:, test_day]
        
        # Clean data to remove NaNs before calculating R².
        clean_pred = pred.dropna()
        clean_orig = orig[pred.notna()]
        
        # Store day-specific R² scores in r2_df.
        r2_df.loc[r2_df.shape[0]] = [test_day, r2_score(clean_orig, clean_pred), state, LABEL_MAPPING.get(state, 3)]
        
    return r2_df.sort_values(by=['Day']), pred_df, kfold_r2
   
def compile_data(mat_file: str, pt_id: int, hemi: int, components: list):
    """
    Compiles and preprocesses data from a MATLAB file for further analysis.
    
    This function loads LFP (local field potential) data and sample entropy from a specified MATLAB file,
    calculates state labels, generates autoregressive lag features, and prepares cosinor model components.
    
    Parameters:
    - mat_file (str): Path to the .mat file containing the data.
    - pt_id (int): The patient identifier.
    - hemi (int): Hemisphere indentifier (0 for left hemisphere, 1 for right hemisphere).
    - components (list): A list with number of cosinor components needed for each patient.
    
    Returns:
    - df (pd.DataFrame): DataFrame containing the raw LFP data loaded from the MATLAB file.
    - master_df (pd.DataFrame): A comprehensive DataFrame that includes the original data, state labels,
                                autoregressive lag features, cosinor model components, and a constant term.
    - se (pd.DataFrame): DataFrame containing sample entropy values loaded from the MATLAB file.
    """
    
    # Load the LFP data and sample entropy from the MATLAB file for the specified patient and hemisphere.
    df, se = load_mat_data(mat_file, pt_id+1, hemi)
    
    # Identify contiguous segments of data based on continuity in days.
    contig = contig_data(df.columns)

    # Initialize master_df with columns representing every possible time point across all days.
    master_df = pd.DataFrame(columns=[timedelta(days=day, hours=t.hour, minutes=t.minute, seconds=t.second) 
                                       for day in df.columns for t in TIME_INDEX])

    # Populate master_df with original LFP data, flattened to match the comprehensive column structure.
    master_df.loc['Original Data'] = df.values.flatten(order='F')
    
    # Calculate and assign state labels to the data points based on the MATLAB file information.
    master_df.loc['State_Label'] = get_state_labels(mat_file, pt_id+1, master_df)
    
    # Assign contiguous segment identifiers to each data point for further analysis.
    master_df.loc['contig'] = [c for c in range(len(contig)-1) for _ in range(contig[c]*144, contig[c+1]*144)]
    
    # Generate autoregressive lag features for each data point.
    for lag in range(1, 145):
        lag_data = []
        for ch in set(master_df.loc['contig'].tolist()):
            lag_data.extend(master_df.loc['Original Data', master_df.loc['contig'] == ch].shift(periods=lag))
        master_df.loc[f'Lag {lag}'] = lag_data
    
    # Calculate cosinor model components (cosine and sine terms) for cyclic patterns in the data.
    for i in range(1, components[pt_id]+1):
        master_df.loc[f'rrr{i}'] = np.cos(2 * np.pi * np.array([(master_df.columns[x].seconds) / 600 
                                       for x in range(len(master_df.columns))]) / (144/i))
        master_df.loc[f'sss{i}'] = np.sin(2 * np.pi * np.array([(master_df.columns[x].seconds) / 600 
                                       for x in range(len(master_df.columns))]) / (144/i))
    
    # Add a constant term to the DataFrame, useful for regression models.
    master_df.loc['constant'] = [1 for _ in range(master_df.columns.shape[0])]

    # Remove columns with any missing data.
    master_df = master_df.dropna(axis=1)
    
    return df, master_df, se

def compile_r2(df: pd.DataFrame, master_df: pd.DataFrame, se: pd.DataFrame, log_df: pd.DataFrame, model: str, pt: tuple, r2_info: dict, ci_info: dict, index: list, saveDict: dict, label_key: dict):
    """
    Compiles R2 metrics, performs model-specific calculations, and aggregates results for logging and analysis.
    
    This function calculates R2 or equivalent performance metrics for different states or conditions within the dataset.
    For each state, it computes mean performance metrics, confidence intervals, and stores data for future analysis.
    
    Parameters:
    - df (pd.DataFrame): The original DataFrame containing raw data.
    - master_df (pd.DataFrame): A DataFrame containing processed data including state labels.
    - se (pd.DataFrame): A DataFrame containing sample entropy data.
    - log_df (pd.DataFrame): A DataFrame to store values for an across-patient regression.
    - model (str): The model identifier (e.g., 'SE' for sample entropy).
    - pt (tuple): Patient identifiers.
    - r2_info (dict): A dictionary to store R2 metrics for each patient and state.
    - ci_info (dict): A dictionary to store confidence intervals for each patient and state.
    - index (list): A list of indices to use for certain operations.
    - saveDict (dict): A dictionary to save various outputs for later analysis.
    - label_key (dict): A dictionary mapping state labels to descriptive names.
    
    Returns:
    - r2_info (dict): Updated dictionary with R2 metrics for each patient and state.
    - ci_info (dict): Updated dictionary with confidence intervals for each patient and state.
    - log_df (pd.DataFrame): Updated DataFrame with values for an across-patient regression.
    """
    
    # Initialize DataFrames for R2 metrics and predictions.
    r2_df = pd.DataFrame(columns = ['Day', 'R2', 'State_Label', 'Logisitic_Label'])
    pred_df = pd.DataFrame(np.nan, columns = df.columns, index = df.index)
    
    # Loop through each state to calculate and store metrics.
    for state in set(master_df.loc['State_Label']):
        #print(f'\nState_Label: {state}')
        gl = master_df.loc[:, master_df.loc['State_Label'] == state]
        
        # Handle 'SE' model separately to calculate sample entropy related metrics.
        if model == 'SE': 
            days = list(set([x.days for x in gl.columns]))
            state_se = []
            for day in days:
                r2_df.loc[r2_df.shape[0]] = [day, se.loc['SE',day], state, LABEL_MAPPING.get(state,3)]
                state_se.append(se.loc['SE',day])
                
            r2_info[pt[1]][f'{label_key[state]}'] = mean(state_se)
            
            # Calculate 95% confidence intervals for sample entropy.
            ci_inter = st.t.interval(confidence=0.95, df=len(state_se)-1, loc=np.mean(state_se),  scale=st.sem(state_se))  
            ci_info[pt[1]][f'{label_key[state]}'] = str(ci_inter)
            
        else:
            # For other models, calculate R2 if data suffices.
            if gl.shape[1] > 145:
                r2_df, pred_df, kfold_r2 = get_r2(gl, r2_df, state, pred_df, df, index, model, components[pt[0]])
                r2_info[pt[1]][f'{label_key[state]}'] = mean(kfold_r2)
                
                # Calculate 95% confidence intervals for R2 metrics.
                ci_inter = st.t.interval(confidence=0.95, df=len(kfold_r2)-1, loc=np.mean(kfold_r2),  scale=st.sem(kfold_r2))  
                ci_info[pt[1]][f'{label_key[state]}'] = str(ci_inter)
    
    # Additional processing and data logging for models other than 'SE'.
    if model != 'SE':      
        saveDict[f'{model}_{pt[1]}_Raw'] = pred_df
    
    # Sort R2 DataFrame by day and perform post-processing.
    r2_df.sort_values(by = ['Day'], inplace=True)   
    saveDict[f'{model}_{pt[1]}_Metric'] = r2_df
    
    # Transpose R2 DataFrame for Delta calculation.
    r2_df = r2_df.T
    
    # Calculate Delta R2 if pre-DBS data exists.
    if 0 in set(r2_df.loc['State_Label']):
        pre_dbs_mean = r2_df.loc['R2', r2_df.loc['State_Label'] == 0.0].mean()
        r2_df.loc['Delta'] = r2_df.loc['R2'] - pre_dbs_mean
    else:
        r2_df.loc['Delta'] = np.full(r2_df.loc['R2'].shape[0], np.nan)
        
    # Log R2 and Delta metrics for each group into log_df.
    for group in set(r2_df.loc['State_Label']):
        if group in [0,2,3]:
            for value in r2_df.loc[:, r2_df.loc['State_Label'] == group]:
                log_df.loc[log_df.shape[0]] = [r2_df.loc['R2', value], r2_df.loc['Delta', value], LABEL_MAPPING[group], pt[1]]
    
    # Return updated dictionaries and log DataFrame.
    return r2_info, ci_info, log_df

def across_pt_regression(log_df: pd.DataFrame, permut_testing: bool, saveDict: dict, model: str):
    """
    Performs logistic regression analysis, evaluates model performance using ROC-AUC and balanced accuracy metrics, and conducts permutation testing for statistical significance.

    Parameters:
    - log_df (pd.DataFrame): The input DataFrame containing the dataset for analysis.
    - permut_testing (bool): Flag indicating whether permutation testing should be performed.
    - saveDict (dict): A dictionary to save predictions, ROC-AUC curves, performance statistics, and permutation testing results (if conducted).
    - model (str): Name of the current metric being tested. 

    Returns:
    - saveDict (dict): A dictionary containing all predictions, ROC-AUC curves, performance statistics, and permutation testing results (if conducted).
    """
    
    # Filtering and preparing data for logistic regression analysis.
    delt = log_df.loc[log_df['dR2'].notna()].iloc[:,[1,2,3]]  # Select rows where 'dR2' is not NaN.
    norm = log_df.iloc[:,[0,2,3]]  # Select first and third columns of log_df.

    # Loop to process 'Delta' and 'Norm' models for logistic regression.
    for model_type, data in zip(['Delta', 'Norm'], [delt, norm]):        
        # Perform logistic regression, save predictions, and calculate ROC curve and AUC.
        true, pred_prob, pred_class = perform_logistic_regression(data)
        saveDict[f'{model}_{model_type}_ROC_AUC_Predictions'] = pd.DataFrame({'True': true, 'Pred_Prob': pred_prob, 'Pred': pred_class})
        
        fpr, tpr, thresholds = roc_curve(true, pred_prob)  # Calculate False Positive Rate, True Positive Rate, and thresholds for ROC curve.
        saveDict[f'{model}_{model_type}_ROC_AUC_Curve'] = pd.DataFrame({'FPR': fpr, 'TPR': tpr, 'Thresholds': thresholds})

        auc = roc_auc_score(true, pred_prob)  # Compute Area Under the ROC curve.
        bacc = balanced_accuracy_score(true, pred_class)  # Compute balanced accuracy score.
        saveDict[f'{model}_{model_type}_ROC_AUC_Performance_Statistics'] = pd.DataFrame({'ROC_AUC': [auc], 'Balanced_Accuracy': [bacc]})

        # Permutation testing conditional block.
        if permut_testing:
            # Perform permutation tests to assess the significance of the observed metrics.
            for rand_strat in ['Randomization', 'Circular_Shift']:
                # Create a copy of the original dataset 
                permut_data = data.copy()
                
                # Initialize lists for permutation testing results.
                dist_auc, dist_bal = [], []
                for iter in range(10000):
                    if rand_strat == 'Randomization':
                        permut_data['Y'] = permut_data['Y'].sample(frac=1)  # Randomly shuffle the dependent variable to simulate chance distribution.
                    else:
                        permut_data = circular_shift(permut_data)
                    true, pred_prob, pred_class = perform_logistic_regression(data)  # Re-run logistic regression with shuffled labels.
    
                    # Store AUC and Balanced Accuracy of permuted labels for significance testing.
                    dist_auc.append(roc_auc_score(true, pred_prob))
                    dist_bal.append(balanced_accuracy_score(true, pred_class))
                
                # Calculate mean chance metrics and p-values from permutation tests.
                saveDict[f'{model}_{model_type}_ROC_AUC_{rand_strat}_Statistics'] = pd.DataFrame({
                    'Chance_AUC': [np.mean(dist_auc)], 
                    'AUC_Pvalue': [(((np.array(dist_auc) > auc).sum())/len(dist_auc))], 
                    'Chance_Balanced_Accuracy': [np.mean(dist_bal)], 
                    'Balanced_Accuracy_PValue': [((np.array(dist_bal) > bacc).sum())/len(dist_bal)]
                })

    # Return a dictionary containing all the results and statistics from the analysis.
    return saveDict

def main(hemi: int, mat_file: str, components: list, pt: list, models: list, permut_testing: bool):
    """
    Main function to run analysis across different models and patients. The function compiles R2 metrics, confidence intervals, and conducts regression analyses.

    Parameters:
    - hemi (int): Hemisphere indentifier (0 for left hemisphere, 1 for right hemisphere).
    - mat_file (str): Path to the .mat file containing the data.
    - components (list): A list with number of cosinor components needed for each patient.
    - pt (list): A list of patient identifiers.
    - models (list): A list of models (e.g., 'SE', 'LinAR') to analyze.
    - permut_testing (bool): Flag indicating whether permutation testing should be performed.

    Returns:
    - saveDict (dict): A dictionary containing all results and metrics from the analysis, structured by model and patient.
    """
    
    # Initialize a dictionary to save all analysis results.
    saveDict = {}
    
    # Iterate through each model specified for analysis.
    for model in models:
        # Initialize dictionaries for R2 metrics and confidence intervals, and a DataFrame to store values for an across-patient regression.
        r2_info, ci_info = {}, {}
        log_df = pd.DataFrame(columns = ['R2' , 'dR2', 'Y', 'PT']) 
        
        # Iterate through each patient.
        for pt_id, pt_name in enumerate(pt):
            
            # Initialize patient-specific entries in dictionaries.
            r2_info[pt_name], ci_info[pt_name] = {}, {}
            
            # Compile data from MATLAB file for the current patient and hemisphere.
            df, master_df, se = compile_data(mat_file, pt_id, hemi, components)
            
            # Prepare labels for regression features.
            index = [f'Lag {i}' for i in range(1,145)]
            
            # Identify significant lag terms for the LinAR model.
            if model == 'LinAR':
                index, res, cont = run_regression(master_df, index)
                while cont == 1:
                    index, res, cont = run_regression(master_df, index)
                    
                #print(f'Sig Index {pt_name}: {index}')
                    
            # Define labels for different states or conditions.
            label_key = {0:'Pre-DBS', 1:'Hypomania', 2:'Non-Responder', 3:'Responder', 4: 'Unlabeled'}
            
            # Compile R2 metrics, confidence intervals, and update log DataFrame.
            r2_info, ci_info, log_df = compile_r2(df, master_df, se, log_df, model, (pt_id, pt_name), r2_info, ci_info, index, saveDict, label_key)

        # Store aggregated state metrics and confidence intervals for each model and patient.
        saveDict[f'{model}_State_Metrics'] = pd.DataFrame(r2_info).T
        saveDict[f'{model}_CI'] = pd.DataFrame(ci_info).T
        
        # Perform across-patient regression analysis, including permutation testing if enabled.
        saveDict = across_pt_regression(log_df, permut_testing, saveDict, model)
        
        # Return the dictionary containing all results.
        return saveDict
    saveDict = {}
        
if __name__ == "__main__":    
    # Requires input from MATLAB
    saveDict = main(hemi, mat_file, components, pt, models, permut_testing)
