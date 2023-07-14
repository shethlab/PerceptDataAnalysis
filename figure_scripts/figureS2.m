addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
% set load directory below that contains data file
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
loadfile = 'VCVS_all_5day_stats.mat';
hem = 1; %left = 1, right = 2
% plot amplitude over time
y_name = 'amplitude (z-scored)'; %y axis label
stat = comb_amp; %setting metric variable here
stat_over_time;
% plot R2 over time
y_name = 'R2'; %y axis label
stat = comb_R2; %setting metric variable here
stat_over_time;