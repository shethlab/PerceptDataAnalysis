# Import statements
import pandas as pd
import datetime as datetime
import numpy as np 
import matlab.engine
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score
import random
from scipy import stats

# Start MATLAB engine
eng = matlab.engine.start_matlab()

# Constants and Utility Functions
L1_LAMBDA = 1e-5
LABEL_MAPPING = {0: 0, 2: 0, 3: 1}
TIME_INDEX = [datetime.time(i // 60, i % 60) for i in range(0, 1440, 10)]
METRIC_MAPPING = {'Cosinor': 'cosinor_R2', 'LinAR': 'linearAR_R2', 'NN_AR': 'nonlinearAR_R2', 'SE': 'entropy'}  # Mapping of metrics to their data identifiers

def load_metric_data(mat_file: str, pt_id: int, hemi: int, sel_metric: str):
    """
    Load metric data for a specific patient and hemisphere from a MATLAB file and create a DataFrame.

    Parameters:
    - mat_file (str): Path to the MATLAB file containing the data.
    - pt_id (int): Patient identifier.
    - hemi (int): Hemisphere identifier (0 for left, 1 for right).
    - sel_metric (str): Selected metric to load.

    Returns:
    - pd.DataFrame: DataFrame containing the loaded metric data, state labels, and other relevant information.
    """
    
    # Create a MATLAB command to load specific patient and hemisphere data
    command = lambda x: f"load('{mat_file}').percept_data.{x}{{{pt_id+1},{2+hemi}}};"
    
    # Load the metric data and create a DataFrame
    store = pd.DataFrame(columns = eng.eval(command("days"))[0])
    
    # Add state labels to the DataFrame    
    for metric in METRIC_MAPPING:
        store.loc[metric,:] = eng.eval(command(METRIC_MAPPING[metric]))
        
    store.loc['State_Label'] = get_state_labels(mat_file, pt_id+1, store) 
    store.loc['Day'] = eng.eval(command("days"))[0] 
    store.loc['Logisitic_Label'] = store.loc['State_Label'].map(LABEL_MAPPING)
    store = store.T.dropna()
    store = store.loc[:,[sel_metric, 'State_Label', 'Day', 'Logisitic_Label']].rename(columns={sel_metric: 'R2'})
    
    return store  

def get_state_labels(mat_file: str, pt_id: int, master_df: pd.DataFrame):
    """
    Retrieves state labels for each data point in a dataset based on a MATLAB file.

    Parameters:
    - mat_file (str): Path to the MATLAB file containing state information.
    - pt_id (int): Patient identifier.
    - master_df (pd.DataFrame): DataFrame containing the dates for which state labels are needed.

    Returns:
    - np.ndarray: An array of state labels for each column in master_df.
    """
    
    # Initialize state labels array with `inf` to indicate unidentified states initially.
    state_label = np.full(master_df.shape[1], np.inf)

    # Pre-assign '0' for the pre-DBS period.
    state_label[[i for i, date in enumerate(master_df.columns) if date < 0]] = 0

    # Loop through each state defined in the MATLAB file and assign labels accordingly.
    for label, state in enumerate(['hypomania', 'non_responder', 'responder']):
        # Extract days corresponding to each state from the MATLAB file.
        state_days = eng.eval(f"load('{mat_file}').zone_index.{state}{{{pt_id},1}};")
        # Assign labels to the dates matching the extracted days.
        state_label[[i for i, date in enumerate(master_df.columns) if date in np.array(state_days)]] = label + 1

    # Replace `inf` labels with '4' for any data points that remain unlabeled.
    state_label = np.where(state_label == np.inf, 4, state_label)
    
    return state_label

def perform_logistic_regression(data: pd.DataFrame):
    """
    Performs logistic regression using Leave-One-Patient-Out Cross-Validation (LOPO-CV) to evaluate model performance.

    Parameters:
    - data (pd.DataFrame): DataFrame containing the R2, dR2, y-label, and patient id for a given metric.

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
    
def compile_r2(hemi: int, mat_file: str, pt: tuple, model: str, log_df: pd.DataFrame, saveDict: dict):
    """
    Compiles R2 metrics, performs model-specific calculations, and aggregates results for logging and analysis.

    This function calculates R2 or equivalent performance metrics for different states or conditions within the dataset.
    For each state, it computes mean performance metrics, confidence intervals, and stores data for future analysis.

    Parameters:
    - hemi (int): Hemisphere identifier (0 for left, 1 for right).
    - mat_file (str): Path to the MATLAB file containing the data.
    - pt (tuple): Patient identifiers.
    - model (str): The model identifier (e.g., 'SE' for sample entropy).
    - log_df (pd.DataFrame): A DataFrame to store values for an across-patient regression.
    - saveDict (dict): A dictionary to save various outputs for later analysis.
    
    Returns:
    - log_df (pd.DataFrame): Updated DataFrame with values for an across-patient regression.
    """
    
    # Initialize DataFrames for R2 metrics and predictions.
    r2_df = load_metric_data(mat_file, pt[0], hemi, model)
    
    if r2_df.empty: # Check that the patient has some non-nan values
        return log_df
    else:  
        # Sort R2 DataFrame by day and perform post-processing.
        r2_df.sort_values(by = ['Day'], inplace=True)   
        
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
        return log_df

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
    log_df = log_df[np.abs(stats.zscore(log_df['R2'])) < 5]     
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
                        permut_data['Y'] = permut_data['Y'].sample(frac=1).values  # Randomly shuffle the dependent variable to simulate chance distribution.
                    else:
                        permut_data = circular_shift(permut_data)
                    true, pred_prob, pred_class = perform_logistic_regression(permut_data)  # Re-run logistic regression with shuffled labels.
    
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

def main(hemi: int, mat_file: str, pt_id: list, pt_name:list, models: list, include_NN: bool, permut_testing: bool):
    """
    Main function to run analysis across different models and patients. The function compiles R2 metrics, confidence intervals, and conducts regression analyses.

    Parameters:
    - hemi (int): Hemisphere identifier (0 for left hemisphere, 1 for right hemisphere).
    - mat_file (str): Path to the .mat file containing the data.
    - pt_id (list): A list of patient identifiers.
    - pt_name (list): A list of patient names.
    - models (list): A list of models (e.g., 'SE', 'LinAR') to analyze.
    - include_NN (bool): Flag indicating whether the nonlinear AR model should be included in calculations
    - permut_testing (bool): Flag indicating whether permutation testing should be performed.

    Returns:
    - saveDict (dict): A dictionary containing all results and metrics from the analysis, structured by model and patient.
    """
    
    # Initialize a dictionary to save all analysis results.
    saveDict = {}
    
    # Do not look for nonlinear AR if it does not exist
    if not include_NN:
        del(METRIC_MAPPING['NN_AR'])
    
    # Iterate through each model specified for analysis.
    for model in models:
        
        # Initialize dictionaries for R2 metrics and confidence intervals, and a DataFrame to store values for an across-patient regression.
        log_df = pd.DataFrame(columns = ['R2' , 'dR2', 'Y', 'PT']) 
        
        # Iterate through each patient.
        for id in range(len(pt_id)):
            
            # Compile R2 metrics, confidence intervals, and update log DataFrame.
            log_df = compile_r2(hemi, mat_file, (pt_id[id], pt_name[id]), model, log_df, saveDict)
        
        # Perform across-patient regression analysis, including permutation testing if enabled.
        saveDict = across_pt_regression(log_df, permut_testing, saveDict, model)
        
    # Return the dictionary containing all results.
    return saveDict
        
if __name__ == "__main__":
# Requires input from MATLAB      
    saveDict = main(hemi, mat_file, pt_id, pt_name, models, include_NN, permut_testing)