addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
% set load directory below that contains data file
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
loadfile = 'VCVS_all_daily_stats.mat';
patients = [3,1,4,5,2];
y_name = 'sample entropy'; %y axis label
stat = comb_entropy; %setting metric variable here
hem = 1; %left = 1, right = 2
stat_over_time;