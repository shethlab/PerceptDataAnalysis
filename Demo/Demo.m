%% This code generates the figure and table outputs used in the manuscript
% from the original raw data. Due to data sharing agreement limitations,
% raw data from patients U001-U003 are not allowed to be shared. Thus,
% figures generated using "demo_data.mat" will be missing these patients.
% Alternatively, an aleady-processed dataset can be loaded under 
% "prepped_data.mat," which also includes U001-U003's calculated metrics.

%% Loading and prepping data (must be run first)
load('demo_data.mat')

percept_data = calc_circadian(percept_data,zone_index,2,2,0,0,[],[],[],1); % full calculations including nonlinear AR & permutation testing

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

%% Tables 3 & 7 (Per-Patient Cosinor R2 T-test)

clear_var_tabs %Close open variable tabs

% Calculate t-test with normal sample size
cosinor_ttest = calc_significance(percept_data_VCVS,'cosinor_R2',zone_index,0);
openvar('cosinor_ttest')

% Calculate t-test with effective sample size
cosinor_ttest_ESS = calc_significance(percept_data_VCVS,'cosinor_R2',zone_index,1);
openvar('cosinor_ttest_ESS')

%% Tables 4 & 7 (Per-Patient Linear AR R2 T-test)

clear_var_tabs %Close open variable tabs

% Calculate t-test with normal sample size
linearAR_ttest = calc_significance(percept_data,'linearAR_R2',zone_index,0);
openvar('linearAR_ttest')

% Calculate t-test with effective sample size
linearAR_ttest_ESS = calc_significance(percept_data,'linearAR_R2',zone_index,1);
openvar('linearAR_ttest_ESS')

%% Tables 5 & 7 (Per-Patient Non-Linear AR R2 T-test)

clear_var_tabs %Close open variable tabs

% Calculate t-test with normal sample size
nonlinearAR_ttest = calc_significance(percept_data,'nonlinearAR_R2',zone_index,0);
openvar('nonlinearAR_ttest')

% Calculate t-test with effective sample size
nonlinearAR_ttest_ESS = calc_significance(percept_data,'nonlinearAR_R2',zone_index,1);
openvar('nonlinearAR_ttest_ESS')

%% Tables 6 & 7 (Per-Patient Sample Entropy T-test)

clear_var_tabs %Close open variable tabs

% Calculate t-test with normal sample size
entropy_ttest = calc_significance(percept_data,'entropy',zone_index,0);
openvar('entropy_ttest')

% Calculate t-test with effective sample size
entropy_ttest_ESS = calc_significance(percept_data,'entropy',zone_index,1);
openvar('entropy_ttest_ESS')

%% Table 8 (Cross-Patient T-tests for All Metrics)

clear_var_tabs %Close open variable tabs

pooled_ttest = calc_pooled_significance(percept_data,zone_index,0);
openvar('pooled_ttest')

pooled_ttest_ESS = calc_pooled_significance(percept_data,zone_index,1);
openvar('pooled_ttest_ESS')

%% Table 9 (ROC Classifier Performance)

clear_var_tabs %Close open variable tabs
openvar('percept_data.Regression_metrics')

%% Table 10 (DeLong Tests)

clear_var_tabs %Close open variable tabs

delong = calc_deLong(percept_data);
openvar('delong')