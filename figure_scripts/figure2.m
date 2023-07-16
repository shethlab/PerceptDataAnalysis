tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'demo_data_prepped_VCVS.mat';
load(strcat(loaddir,loadfile));

% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data_VCVS,1,zone_index_VCVS);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data_VCVS,1,zone_index_VCVS);
toc