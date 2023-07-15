tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
load('/Users/sameerrajesh/Desktop/DATA/demo_data_prepped.mat');

% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data,2,zone_index);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data,2,zone_index);
toc