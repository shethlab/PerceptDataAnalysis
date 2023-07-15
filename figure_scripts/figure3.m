tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
load('/Users/sameerrajesh/Desktop/DATA/audioinfo.mat');
dbsSpeechAnalysis;
%% Audio Statistics located in audiostats, other variables cleared from workspace
clearvars -except audiostats
toc