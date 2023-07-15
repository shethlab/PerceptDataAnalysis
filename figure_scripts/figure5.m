tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
% set load directory below that contains data file

load('/Users/sameerrajesh/Desktop/DATA/demo_data_prepped_1day.mat')
patients = [3,1,4,5,2];
y_name = 'sample entropy'; %y axis label
stat = percept_data1day.entropy; %setting metric variable here
hem = 1; %left = 1, right = 2
stat_over_time(percept_data1day,'entropy',hem,zone_index);
toc