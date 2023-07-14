# Import the necessary libraries 
import pandas as pd 
import matlab.engine
from sklearn.model_selection import KFold
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score
from sklearn.linear_model import LogisticRegression

HEMISPHERE = 1 # 1 for Left hemisphere and 2 for right hemisphere

# Create a pandas DataFrame by loading data from a .mat file
def create_dataframe(mat_file, eng, num):
    # Load the entropy data from the .mat file
    data = pd.DataFrame(eng.eval(f"load('{mat_file}').percept_data.entropy{{{num},{HEMISPHERE+1}}};"))
    # Load the label data from the .mat file
    labels = pd.DataFrame(eng.eval(f"load('{mat_file}').percept_data.grouplabels{{{num},{HEMISPHERE+1}}};"))
    
    # Concatenate data and labels DataFrames
    concat = pd.concat([data,labels]).T
    concat.columns = ['Sample_Entropy', 'Labels']
    return concat

# Perform logistic regression and cross-validation
def perform_logistic_regression(X, y):
    X = X.reshape(-1,1) # Reshape X to be 2D
    cv = KFold(n_splits = y.shape[0], shuffle=True) # KFold cross-validator
    true, pred, pred_rd = [], [], [] # Lists to store true labels, predicted probabilities and predicted classes
    
    for train_ix, test_ix in cv.split(X, y):
        # Split the data into training and test sets
        train_X, test_X = X[train_ix], X[test_ix]
        train_y, test_y = y[train_ix], y[test_ix]
        
        # Train the logistic regression model
        clf = LogisticRegression(class_weight='balanced').fit(train_X, train_y)
        
        # Extend the lists with the test labels and predictions
        true.extend(test_y)
        pred.extend(clf.decision_function(test_X))
        pred_rd.extend(clf.predict(test_X))
        
    return true, pred, pred_rd

def main():
    eng = matlab.engine.start_matlab()

    pt_numbers = [1, 2, 4, 5, 6]

    for pt in pt_numbers:
        # Create a DataFrame for the patient data
        all_data  = create_dataframe('004_test.mat', eng, 1)
        
        # Select rows where Labels are either 0 or 1
        comp = all_data[(all_data['Labels'] == 0) | (all_data['Labels'] == 1)]
        
        # Separate the DataFrame into features (X) and labels (y)
        X = comp['Sample_Entropy'].to_numpy()
        y = comp['Labels'].to_numpy()

        # Perform logistic regression
        true, pred, pred_rd = perform_logistic_regression(X, y)
        # Compute ROC curve
        fpr, tpr, thresholds = roc_curve(true, pred)
        # Compute AUC
        auc = roc_auc_score(true, pred)
        # Compute Balanced Accuracy
        bacc = balanced_accuracy_score(true,pred_rd)

        # Print results
        print(f'PT00{pt}')
        print(f'AUC: {auc}')
        print(f'Balanced Accuracy: {bacc}\n\n')

if __name__ == '__main__':
    main()
