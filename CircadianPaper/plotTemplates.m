addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
load('/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/VCVS_all_daily_stats.mat');
load('/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/singleDayTemplateDates.mat');
%% Average Templates
filled = {};
logged = {};
wrapped = 1;
bilateral = 1;
for i = 1:5
    filled{i,1} = comb_LFP_raw_matrix{i,1};
    logged{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        filled{i,j} = fillData(comb_LFP_raw_matrix{i,j},comb_days{i,j-1});
        logged{i,j} = decibelize(filled{i,j});
    end
end
 
zoneTemplateGeneration(logged,comb_acro,comb_p,comb_days,1,1,wrapped,[],bilateral)

%% Single Day Templates
% Left Hem only 
days = [];
for j = 1:3

%     zoneTemplateGeneration(logged,comb_acro,comb_p,comb_days,0,0,1,daystoplot{j},0);
end
