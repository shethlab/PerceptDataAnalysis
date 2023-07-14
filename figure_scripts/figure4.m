addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
% set desired hemisphere and target
wrapped = 1; % 1 = circular plots, 0 = linear plots
bilateral = 1; % 1 = plot both hemispheres, 0 = plot left hemisphere only
sd = 0; % 1 = only plot averages, 0 = only plot single day templates
% Plot average templates
plotTemplates;
% Plot unwrapped average templates
wrapped = 0;
% Plot single day templates
sd = 1;
plotTemplates;