addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'demo_data_prepped_VCVS.mat';
load(strcat(loaddir,loadfile));

figure;
patients = [3,1,4,5,2];
y_name = 'amplitude (z-scored)'; %y axis label
hem = 1; %left = 1, right = 2
stat_over_time(percept_data_VCVS,'amplitude',hem,zone_index_VCVS);

figure;
patients = [3,1,4,5,2];
y_name = 'R2'; %y axis label
hem = 1; %left = 1, right = 2
stat_over_time(percept_data_VCVS,'cosinor_R2',hem,zone_index_VCVS);

