tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
load('/Users/sameerrajesh/Desktop/DATA/demo_data.mat');
percept_data = circadian_calc(percept_data,2,2,[],1);
percept_data1day = circadian_calc(percept_data,0,0,[],1);
percept_data.entropy = percept_data1day.entropy;
toc