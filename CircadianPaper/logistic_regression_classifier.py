import numpy as np 
import pandas as pd 
import matlab.engine
import datetime
from sklearn.model_selection import KFold
from sklearn.metrics import roc_curve, roc_auc_score, balanced_accuracy_score, confusion_matrix
from sklearn.linear_model import LogisticRegression
import EntropyHub as EH

def create_dataframe(mat_file, eng, num):
    time = [datetime.time(i // 60, i % 60) for i in range(0,1440,10)]
    df = pd.DataFrame(eng.eval(f"load('{mat_file}').filled{{{num},2}};"), index= time, columns= eng.eval(f"load('VCVS_all_filled.mat').comb_days{{{num},1}};")[0])
    return df

def add_group_labels(df, group_labels):
    df.loc['Group'] = group_labels
    return df

def calculate_sample_entropy(df, pt_name, m, r, t, l, groups):
    pt = df.T
    sampEn_values = []
    for group in groups:
        data = pt[pt['Group'] == group].iloc[:,:-1].dropna()
        for day in range(data.shape[0]):
            sampEn_values.append((EH.SampEn(data.iloc[day,:].to_numpy(), m = m, r = r, tau = t, Logx = l)[0][2], pt_name, group))
    return sampEn_values

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

def main():
    eng = matlab.engine.start_matlab()

    pt_numbers = [102, 105, 101, 103, 104]
    id_num = range(1,6)
    group_labels = [[0]*49 + [1]*48 + [3]*53, 
                    [0]*7 + [1]*16 + [2]*15 + [1]*61,
                    [0]*10 + [1]*9 + [2]*69 + [3]*186,
                    [0]*45 + [1]*5 + [2]*90 + [3]*179,
                    [0]*14 + [1]*187]
    classifier_groups = [[0,3],[0,1],[0,3],[0,3],[0,1]]

    m, r, t, l = 2, 3.6, 1, np.exp(1)

    sampEn_values = []
    
    for num, group_label, class_group, id in zip(pt_numbers, group_labels, classifier_groups, id_num):
        df = create_dataframe('filled.mat', eng, id)
        df = add_group_labels(df, group_label)
        sampEn_values.extend(calculate_sample_entropy(df, f'PT{num}', m, r, t, l, class_group))

    sampEn_values_df = pd.DataFrame(sampEn_values, columns=['Sample Entropy', 'PT', 'Group'])
    
    
    with pd.ExcelWriter('roc_curves.xlsx') as writer:
        for pt_name in sampEn_values_df['PT'].unique():
            rocc = {}
            
            df = sampEn_values_df[sampEn_values_df['PT'] == pt_name]
            X = df['Sample Entropy'].to_numpy()
            y = df['Group'].apply(lambda x: 0 if x == 0 else 1).to_numpy()
            true, pred, pred_rd = perform_logistic_regression(X, y)
            fpr, tpr, thresholds = roc_curve(true, pred)
            auc = roc_auc_score(true, pred)
            bacc = balanced_accuracy_score(true,pred_rd)
            
            rocc['TPR'] = tpr
            rocc['FPR'] = fpr
            
            
            pd.DataFrame(rocc).to_excel(writer, sheet_name=pt_name)
            
            print(f'{pt_name}')
            print(f'AUC: {auc}')
            print(f'Balanced Accuracy: {bacc}\n\n')

if __name__ == '__main__':
    main()