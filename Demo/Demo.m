%% This code generates the figure and table outputs used in the manuscript
% from the original raw data. Due to data sharing agreement limitations,
% raw data from patients U001-U003 are not allowed to be shared. Thus,
% figures generated using "demo_data.mat" will be missing these patients.
% Alternatively, an aleady-processed dataset can be loaded under 
% "prepped_data.mat," which also includes U001-U003's calculated metrics.

%% Loading and prepping data (must be run first)
load('demo_data.mat')

percept_data = calc_circadian(percept_data,zone_index,2,2,0,0,1,0,0,1); % full calculations including nonlinear AR & permutation testing

%% Figure 1 (PSD Plots)

plot_PSD(percept_data,8.79,4,3)

%% Figure 2 (Left Hemisphere Heatmaps & Cosinor Plots)

plot_heatmap(percept_data,1,zone_index,1)
plot_cosinor(percept_data,1,zone_index,1)

%% Figure 3 (Left Hemisphere Detailed Non-Responder Plots)

plot_templates(percept_data,'B006',1,zone_index,[-5,-2,95,168])
plot_metrics(percept_data,'B006',1,[-9.5,-6.5],[539.5,542.5],zone_index)

%% Figure 4 (Left Hemisphere Detailed Responder Plots)

plot_templates(percept_data,'B001',1,zone_index,[-45,-14,64,95])
plot_metrics(percept_data,'B001',1,[-12,-9],[84,87],zone_index)

%% Figure 5 (Left Hemisphere Before-After Plots & ROCs)

plot_deltas(percept_data,1)

%% Figure S1 (Right Hemisphere Heatmaps & Cosinor Plots)

plot_heatmap(percept_data,2,zone_index,1)
plot_cosinor(percept_data,2,zone_index,1)

%% Figure S2 (Left Hemisphere Expanded Violin Plots in Responders)


%% Figure S3 (Left Hemisphere Expanded Violin Plots in Non-Responders)


%% Table 2 (Pre-DBS Single Cosinor Fit)

clear_var_tabs %Close open variable tabs

cosinor_fits = calc_preDBS_cosinor(percept_data,1);
openvar('cosinor_fits')

%% Table 3 (5-Fold Cross-Validation Means & Confidence Intervals)

clear_var_tabs %Close open variable tabs

openvar('percept_data.kfold')
openvar('percept_data.kfold_CI')

%% Table 4 (Difference in Cross-Validation Means)

clear_var_tabs %Close open variable tabs

% Calculate deltas by subtracting chronic status kfold means from pre-DBS kfold means
for hemisphere = 1:2
    kfold_deltas.cosinor(hemisphere,:) = percept_data.kfold.cosinor{hemisphere}.('Pre-DBS') - nanmin([percept_data.kfold.cosinor{hemisphere}.('Responder'),percept_data.kfold.cosinor{hemisphere}.('Non-Responder')],[],2);
    kfold_deltas.linearAR(hemisphere,:) = percept_data.kfold.linearAR{hemisphere}.('Pre-DBS') - nanmin([percept_data.kfold.linearAR{hemisphere}.('Responder'),percept_data.kfold.linearAR{hemisphere}.('Non-Responder')],[],2);
    kfold_deltas.entropy(hemisphere,:) = percept_data.kfold.entropy{hemisphere}.('Pre-DBS') - nanmin([percept_data.kfold.entropy{hemisphere}.('Responder'),percept_data.kfold.entropy{hemisphere}.('Non-Responder')],[],2);    
    try
        kfold_deltas.nonlinearAR(hemisphere,:) = percept_data.kfold.nonlinearAR{hemisphere}.('Pre-DBS') - nanmin([percept_data.kfold.nonlinearAR{hemisphere}.('Responder'),percept_data.kfold.nonlinearAR{hemisphere}.('Non-Responder')],[],2);
    end
end

kfold_deltas.cosinor = array2table(kfold_deltas.cosinor,"VariableNames",percept_data.kfold.cosinor{hemisphere}.Subject,'RowNames',{'Left','Right'});
kfold_deltas.linearAR = array2table(kfold_deltas.linearAR,"VariableNames",percept_data.kfold.linearAR{hemisphere}.Subject,'RowNames',{'Left','Right'});
kfold_deltas.entropy = array2table(kfold_deltas.entropy,"VariableNames",percept_data.kfold.entropy{hemisphere}.Subject,'RowNames',{'Left','Right'});
try
    kfold_deltas.nonlinearAR = array2table(kfold_deltas.nonlinearAR,"VariableNames",percept_data.kfold.nonlinearAR{hemisphere}.Subject);
end

openvar('kfold_deltas')

%% Table 5 (Cosinor R2 T-test)

clear_var_tabs %Close open variable tabs

cosinor_ttest = calc_significance(percept_data,'cosinor_R2',zone_index);
openvar('cosinor_ttest')

%% Table 6 (Linear AR R2 T-test)

clear_var_tabs %Close open variable tabs

linearAR_ttest = calc_significance(percept_data,'linearAR_R2',zone_index);
openvar('linearAR_ttest')

%% Table 7 (Non-Linear AR R2 T-test)

clear_var_tabs %Close open variable tabs

nonlinearAR_ttest = calc_significance(percept_data,'nonlinearAR_R2',zone_index);
openvar('nonlinearAR_ttest')

%% Table 8 (Sample Entropy T-test)

clear_var_tabs %Close open variable tabs

entropy_ttest = calc_significance(percept_data,'entropy',zone_index);
openvar('entropy_ttest')

%% Table 9 (ROC Classifier Performance)

clear_var_tabs
openvar('percept_data.ROC_metrics')

%% Table 10 (DeLong Tests)

clear_var_tabs

delong = calc_delong(percept_data);
openvar('delong')