function plotTemplates(percept_data,wrapped,bilateral,sd,daystoplot);

%% Average Templates
filled = {};
logged = {};
for i = 1:5
    filled{i,1} = percept_data.LFP_raw_matrix{i,1};
    logged{i,1} = percept_data.LFP_raw_matrix{i,1};
    for j = 2:3
        filled{i,j} = fillData(percept_data.LFP_raw_matrix{i,j},percept_data.days{i,j});
        logged{i,j} = decibelize(filled{i,j});
    end
end
if sd == 0
zoneTemplateGeneration(logged,percept_data.acrophase,percept_data.cosinor_p,percept_data.days,1,1,wrapped,[],bilateral)
else
end

%% Single Day Templates
% Left Hem only 
days = [];
if sd == 1
for j = 1:3

     zoneTemplateGeneration(logged,percept_data.acrophase,percept_data.cosinor_p,percept_data.days,0,0,1,daystoplot{j},0);
end
end