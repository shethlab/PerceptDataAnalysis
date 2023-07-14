addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'))
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
loadfile = 'GPI_all.mat';
patients = [1,4]; % Set GPi patient range
% Set desired hemisphere and target
hem = 1; % left = 1 ; right = 2
target = 2; % VCVS = 1 ; GPi = 2
% Plot left hemisphere GPi heatmaps
circadian_heat_map;
% Plot left hemisphere GPi acrophase plots
acrophase_plots;
% Plot left hemisphere GPi sample entropy
loadfile = 'GPI_all_daily_stats.mat';
y_name = 'sample entropy'; %y axis label
stat = comb_entropy; %setting metric variable here
stat_over_time;
% Switch to right hemisphere
hem = 2; % left = 1 ; right = 2
target = 2; % VCVS = 1 ; GPi = 2
% Plot right hemisphere GPi heatmaps
circadian_heat_map;
% Plot right hemisphere GPi acrophase plots
acrophase_plots;
% Plot right hemisphere GPi sample entropy
loadfile = 'GPI_all_daily_stats.mat';
y_name = 'sample entropy'; %y axis label
stat = comb_entropy; %setting metric variable here
stat_over_time;