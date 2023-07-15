addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
load('/Users/sameerrajesh/Desktop/DATA/demo_data_prepped.mat');

figure;
patients = [3,1,4,5,2];
y_name = 'amplitude (z-scored)'; %y axis label
hem = 1; %left = 1, right = 2
stat_over_time(percept_data,'amplitude',hem,zone_index);

figure;
patients = [3,1,4,5,2];
y_name = 'R2'; %y axis label
hem = 1; %left = 1, right = 2
stat_over_time(percept_data,'cosinor_R2',hem,zone_index);

