tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'streamsplot.mat';
load(strcat(loaddir,loadfile));
PSD_generation_subplot;
toc