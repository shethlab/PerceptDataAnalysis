addpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis/CircadianPaper')
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
loadfile = 'VCVS_all.mat';
% set desired hemisphere and target
hem = 1; % left = 1 ; right = 2
target = 1; % VCVS = 1 ; GPi = 2
% Plot left hemisphere VS heatmaps
circadian_heat_map;
% Plot left hemisphere VS acrophase plots
acrophase_plots;