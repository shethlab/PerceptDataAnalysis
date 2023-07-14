import numpy as np 
import pandas as pd 
import matlab.engine
import datetime
from sklearn.model_selection import KFold
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score, confusion_matrix
from sklearn.linear_model import LogisticRegression
import EntropyHub as EH
from statistics import mean, stdev

# Function to create a DataFrame from .mat files
def create_dataframe(mat_file, eng, num):
    time = [datetime.time(i // 60, i % 60) for i in range(0,1440,10)]
    df = pd.DataFrame(eng.eval(f"load('{mat_file}').filled{{{num},2}};"), index= time, columns= eng.eval(f"load('VCVS_all_filled.mat').comb_days{{{num},1}};")[0])
    return df

# Function to add group labels to the DataFrame
def add_group_labels(df, group_labels):
    df.loc['Group'] = group_labels
    return df

# Function to calculate Sample Entropy for each group in the DataFrame
def calculate_sample_entropy(df, pt_name, m, r, t, l, groups):
    pt = df.T
    sampEn_values = []
    for group in groups:
        data = pt[pt['Group'] == group].iloc[:,:-1].dropna()
        for day in range(data.shape[0]):
            sampEn_values.append((EH.SampEn(data.iloc[day,:].to_numpy(), m = m, r = r, tau = t, Logx = l)[0][2], pt_name, group))
    return sampEn_values

# Function to perform Logistic Regression using K-fold cross validation
def perform_logistic_regression(X, y):
    X = X.reshape(-1,1)
    cv = KFold(n_splits = y.shape[0], shuffle=True)
    true, pred, pred_rd = [], [], []
    
    for train_ix, test_ix in cv.split(X, y):
        train_X, test_X = X[train_ix], X[test_ix]
        train_y, test_y = y[train_ix], y[test_ix]
        
        clf = LogisticRegression(class_weight='balanced').fit(train_X, train_y)
        
        true.extend(test_y)
        pred.extend(clf.predict_proba(test_X)[:,1])
        pred_rd.extend(clf.predict(test_X))
    return true, pred, pred_rd

# Hemisphere option
hemi = 0

def main():
    # Start a Matlab session
    eng = matlab.engine.start_matlab()

    if hemi == 0:
        # Define patients' numbers, their corresponding IDs, group labels and groups for classification for the left hemisphere
        # These will vary depending on the specific application
        pt_numbers = [1, 2, 4, 5, 6]
        id_num = range(1,6)
        group_labels = [[0]*49 + [1]*48 + [3]*53, 
                        [0]*7 + [1]*16 + [2]*15 + [1]*61,
                        [0]*10 + [1]*9 + [2]*69 + [3]*186,
                        [0]*45 + [1]*5 + [2]*90 + [3]*179,
                        [0]*14 + [1]*187]
        classifier_groups = [[0,3],[0,1],[0,3],[0,3],[0,1]]

        responders = ['PT004', 'PT001', 'PT005']
    else:
        # Same as above, but for the right hemisphere
        pt_numbers = [1, 2, 5, 6]
        id_num = [1,2,4,5]
        group_labels = [[0]*49 + [1]*48 + [3]*53, 
                        [0]*7 + [1]*28 + [2]*15 + [1]*160,
                        [0]*45 + [1]*5 + [2]*90 + [3]*179,
                        [0]*14 + [1]*270]
        
        classifier_groups = [[0,3],[0,1],[0,3],[0,1]]

        responders = ['PT001', 'PT005']

    m, r, t, l = 2, 3.6, 1, np.exp(1)

    sampEn_values = []
    
    # Loop through each patient number, group label, classification group, and ID
    for num, group_label, class_group, id in zip(pt_numbers, group_labels, classifier_groups, id_num):
        df = create_dataframe('filled.mat', eng, id)  # Create the DataFrame from .mat files
        df = add_group_labels(df, group_label)  # Add group labels to the DataFrame
        sampEn_values.extend(calculate_sample_entropy(df, f'PT00{num}', m, r, t, l, class_group))  # Calculate Sample Entropy

    sampEn_values_df = pd.DataFrame(sampEn_values, columns=['Sample Entropy', 'PT', 'Group'])
    
    # Placeholder lists for storing performance metrics
    sen = []
    fpr = []
    fnr = []
    spec = []

    # Loop through each responder to calculate and print performance metrics
    for pt_name in responders:
                
        df = sampEn_values_df[sampEn_values_df['PT'] == pt_name]
        X = df['Sample Entropy'].to_numpy()
        y = df['Group'].apply(lambda x: 0 if x == 0 else 1).to_numpy()
        true, pred, pred_rd = perform_logistic_regression(X, y)
        
        tn, fp, fn, tp = confusion_matrix(true,pred_rd).ravel()
        
        sen.append(tp/(tp+fn))
        fpr.append(fp/(fp+tn))
        fnr.append(fn/(tp+fn))
        spec.append(tn/(fp+tn))
        
    # Print performance metrics for the responders
    print(f'               Responders')
    print(f'Sensitivity: {round(mean(sen),3)} STD: {round(stdev(sen),3)}')
    print(f'False Positive Rate: {round(mean(fpr),3)} STD: {round(stdev(fpr),3)}')
    print(f'False Negative Rate: {round(mean(fnr),3)} STD: {round(stdev(fnr),3)}')
    print(f'Specificity: {round(mean(spec),3)} STD: {round(stdev(spec),3)}')

    # Reset placeholder lists for non-responders
    sen = []
    fpr = []
    fnr = []
    spec = []

    # Loop through each non-responder to calculate and print performance metrics
    for pt_name in ['PT002', 'PT006']:
                
        df = sampEn_values_df[sampEn_values_df['PT'] == pt_name]
        X = df['Sample Entropy'].to_numpy()
        y = df['Group'].apply(lambda x: 0 if x == 0 else 1).to_numpy()
        true, pred, pred_rd = perform_logistic_regression(X, y)
        
        tn, fp, fn, tp = confusion_matrix(true,pred_rd).ravel()

        sen.append(tp/(tp+fn))
        fpr.append(fp/(fp+tn))
        fnr.append(fn/(tp+fn))
        spec.append(tn/(fp+tn))
        
    # Print performance metrics for the non-responders
    print(f'               Non-Responders')
    print(f'Sensitivity: {round(mean(sen),3)} STD: {round(stdev(sen),3)}')
    print(f'False Positive Rate: {round(mean(fpr),3)} STD: {round(stdev(fpr),3)}')
    print(f'False Negative Rate: {round(mean(fnr),3)} STD: {round(stdev(fnr),3)}')
    print(f'Specificity: {round(mean(spec),3)} STD: {round(stdev(spec),3)}')

if __name__ == "__main__":
    main()
