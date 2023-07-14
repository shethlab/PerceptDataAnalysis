# Import necessary libraries
import numpy as np 
import pandas as pd 
import matlab.engine
import datetime
from sklearn.model_selection import KFold
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score, confusion_matrix
from sklearn.linear_model import LogisticRegression
import EntropyHub as EH

# Function to create a pandas dataframe from a Matlab (.mat) file
def create_dataframe(mat_file, eng, num):
    time = [datetime.time(i // 60, i % 60) for i in range(0,1440,10)] # creating a list of times from 00:00 to 23:50 with an interval of 10 minutes
    df = pd.DataFrame(eng.eval(f"load('{mat_file}').filled{{{num},2}};"), index= time, columns= eng.eval(f"load('VCVS_all_filled.mat').comb_days{{{num},1}};")[0]) # load the data from Matlab file into a DataFrame
    return df

# Function to add group labels to the dataframe
def add_group_labels(df, group_labels):
    df.loc['Group'] = group_labels # add a row labeled 'Group' to the dataframe
    return df

# Function to calculate the sample entropy for each day of each patient
def calculate_sample_entropy(df, pt_name, m, r, t, l, groups):
    pt = df.T
    sampEn_values = []
    for group in groups:
        data = pt[pt['Group'] == group].iloc[:,:-1].dropna() # get only the rows with the corresponding group label and exclude the last column
        for day in range(data.shape[0]):
            sampEn_values.append((EH.SampEn(data.iloc[day,:].to_numpy(), m = m, r = r, tau = t, Logx = l)[0][2], pt_name, group)) # calculate the Sample Entropy and add it to the list along with the patient name and group
    return sampEn_values

# Function to perform logistic regression using k-fold cross-validation
def perform_logistic_regression(X, y):
    X = X.reshape(-1,1)
    cv = KFold(n_splits = y.shape[0], shuffle=True) # define the cross-validation strategy
    true, pred, pred_rd = [], [], [] # define empty lists to store the true labels and predictions
    
    # perform k-fold cross-validation
    for train_ix, test_ix in cv.split(X, y):
        train_X, test_X = X[train_ix], X[test_ix]
        train_y, test_y = y[train_ix], y[test_ix]
        
        clf = LogisticRegression(class_weight='balanced').fit(train_X, train_y) # fit the logistic regression model on the training data
        
        true.extend(test_y) # append the true labels of the test data
        pred.extend(clf.predict_proba(test_X)[:,1]) # append the predicted probabilities of the positive class for the test data
        pred_rd.extend(clf.predict(test_X)) # append the predicted classes for the test data
    return true, pred, pred_rd

hemi = 0 # 0 for left hemisphere and 1 for right hemisphere 

def main():
    eng = matlab.engine.start_matlab() # start a Matlab engine

    # set different parameters based on the selected hemisphere
    if hemi == 0:
        # define patients' numbers, their corresponding IDs, group labels and groups for classification for the left hemisphere
        pt_numbers = [102, 105, 101, 103, 104]
        id_num = range(1,6)
        group_labels = [[0]*49 + [1]*48 + [3]*53, 
                        [0]*7 + [1]*16 + [2]*15 + [1]*61,
                        [0]*10 + [1]*9 + [2]*69 + [3]*186,
                        [0]*45 + [1]*5 + [2]*90 + [3]*179,
                        [0]*14 + [1]*187]
        classifier_groups = [[0,3],[0,1],[0,3],[0,3],[0,1]]
    else:
        # define patients' numbers, their corresponding IDs, group labels and groups for classification for the right hemisphere
        pt_numbers = [1, 2, 5, 6]
        id_num = [1,2,4,5]
        group_labels = [[0]*49 + [1]*48 + [3]*53, 
                        [0]*7 + [1]*28 + [2]*15 + [1]*160,
                        [0]*45 + [1]*5 + [2]*90 + [3]*179,
                        [0]*14 + [1]*270]
        
        classifier_groups = [[0,3],[0,1],[0,3],[0,1]]

    m, r, t, l = 2, 3.6, 1, np.exp(1) # set parameters for the Sample Entropy calculation

    sampEn_values = []
    
    # calculate the Sample Entropy for each day of each patient
    for num, group_label, class_group, id in zip(pt_numbers, group_labels, classifier_groups, id_num):
        df = create_dataframe('filled.mat', eng, id) # create a dataframe from the Matlab file
        df = add_group_labels(df, group_label) # add group labels to the dataframe
        sampEn_values.extend(calculate_sample_entropy(df, f'PT{num}', m, r, t, l, class_group)) # calculate the Sample Entropy and add the values to the list

    sampEn_values_df = pd.DataFrame(sampEn_values, columns=['Sample Entropy', 'PT', 'Group']) # create a dataframe from the list of Sample Entropy values
    
    # save the ROC curves of each patient to an Excel file
    with pd.ExcelWriter('roc_curves.xlsx') as writer:
        for pt_name in sampEn_values_df['PT'].unique():
            rocc = {}
            
            df = sampEn_values_df[sampEn_values_df['PT'] == pt_name]
            X = df['Sample Entropy'].to_numpy()
            y = df['Group'].apply(lambda x: 0 if x == 0 else 1).to_numpy() # recode the group labels to a binary format (0 and 1)
            true, pred, pred_rd = perform_logistic_regression(X, y) # perform logistic regression
            fpr, tpr, thresholds = roc_curve(true, pred) # calculate the ROC curve
            auc = roc_auc_score(true, pred) # calculate the AUC
            bacc = balanced_accuracy_score(true,pred_rd) # calculate the Balanced Accuracy
            
            rocc['TPR'] = tpr
            rocc['FPR'] = fpr
            
            pd.DataFrame(rocc).to_excel(writer, sheet_name=pt_name) # save the ROC curve to an Excel file
            
            print(f'{pt_name}') # print the patient name
            print(f'AUC: {auc}') # print the AUC
            print(f'Balanced Accuracy: {bacc}\n\n') # print the Balanced Accuracy

if __name__ == '__main__':
    main() # call the main function
