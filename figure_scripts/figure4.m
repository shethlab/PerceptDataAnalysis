addpath(genpath('/Users/sameeerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
load([loaddir 'demo_data_prepped_1day.mat']);
load([loaddir 'singleDayTemplateDates.mat']);
% set desired hemisphere and target
wrapped = 1; % 1 = circular plots, 0 = linear plots
bilateral = 0; % 1 = plot both hemispheres, 0 = plot left hemisphere only
sd = 0; % 1 = only plot averages, 0 = only plot single day templates
% Plot average templates
plotTemplates(percept_data1day,wrapped,bilateral,sd,[]);
% Plot unwrapped average templates
wrapped = 0;
plotTemplates(percept_data1day,wrapped,bilateral,sd,[]);
% Plot single day templates
wrapped = 1;
sd = 1;
plotTemplates(percept_data1day,wrapped,bilateral,sd,daystoplot);