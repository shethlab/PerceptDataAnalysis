addpath(genpath('/Users/nabeeldiab/Documents/GitHub/PerceptDataAnalysis'));
load([loaddir 'VCVS_all_daily_stats.mat']);
load([loaddir 'singleDayTemplateDates.mat']);
%% Average Templates
filled = {};
logged = {};
for i = 1:5
    filled{i,1} = comb_LFP_raw_matrix{i,1};
    logged{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        filled{i,j} = fillData(comb_LFP_raw_matrix{i,j},comb_days{i,j-1});
        logged{i,j} = decibelize(filled{i,j});
    end
end
if sd == 0
zoneTemplateGeneration(logged,comb_acro,comb_p,comb_days,1,1,wrapped,[],bilateral)
else
end

%% Single Day Templates
% Left Hem only 
days = [];
if sd == 1
for j = 1:3

%     zoneTemplateGeneration(logged,comb_acro,comb_p,comb_days,0,0,1,daystoplot{j},0);
end
else
end