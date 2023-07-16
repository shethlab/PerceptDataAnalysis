tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'audioinfo.mat';
load(strcat(loaddir,loadfile));
dbsSpeechAnalysis;
%% Audio Statistics located in audiostats, other variables cleared from workspace
clearvars -except audiostats
toc