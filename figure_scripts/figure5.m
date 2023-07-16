tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'demo_data_prepped1day_VCVS.mat';
load(strcat(loaddir,loadfile));
patients = [3,1,4,5,2];
y_name = 'sample entropy'; %y axis label
stat = percept_data1day_VCVS.entropy; %setting metric variable here
hem = 1; %left = 1, right = 2
stat_over_time(percept_data1day_VCVS,'entropy',hem,zone_index_VCVS);
toc