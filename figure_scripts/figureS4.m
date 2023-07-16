addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'))
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'demo_data_prepped_GPi.mat';

load(strcat(loaddir,loadfile));



% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data_GPi,1,zone_index_GPi);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data_GPi,1,zone_index_GPi);


% Plot left hemisphere GPi sample entropy
y_name = 'sample entropy'; %y axis label
stat_over_time(percept_data_GPi,'entropy',1,zone_index_GPi);


% Switch to right hemisphere
% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data_GPi,2,zone_index_GPi);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data_GPi,2,zone_index_GPi);


% Plot left hemisphere GPi sample entropy
y_name = 'sample entropy'; %y axis label
stat_over_time(percept_data_GPi,'entropy',2,zone_index_GPi);