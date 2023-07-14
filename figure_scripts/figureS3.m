addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
% set load directory below that contains data file
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
loadfile = 'VCVS_all_daily_stats.mat';
y_name = 'sample entropy'; %y axis label
stat = comb_entropy; %setting metric variable here
hem = 2; %left = 1, right = 2
stat_over_time;