addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'))
load('/Users/sameerrajesh/Desktop/DATA/demo_data_GPi_prepped.mat')

%%patients = [1,4]; % Set GPi patient range

% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data,1,zone_index);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data,1,zone_index);


% Plot left hemisphere GPi sample entropy
y_name = 'sample entropy'; %y axis label
stat_over_time(percept_data,'entropy',1,zone_index);





% Switch to right hemisphere
% Plot left hemisphere VS heatmaps
circadian_heatmap(percept_data,2,zone_index);
% Plot left hemisphere VS acrophase plots
circadian_acrophase(percept_data,2,zone_index);


% Plot left hemisphere GPi sample entropy
y_name = 'sample entropy'; %y axis label
stat_over_time(percept_data,'entropy',2,zone_index);