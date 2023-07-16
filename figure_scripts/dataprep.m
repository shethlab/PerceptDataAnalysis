tic
addpath(genpath('/Users/sameerrajesh/Desktop/GitHub/PerceptDataAnalysis'));
loaddir = '/Users/sameerrajesh/Desktop/DATA/';
loadfile = 'demo_data.mat';
load(strcat(loaddir,loadfile));

% % if exist("percept_data_VCVS")
% %     percept_data_VCVS = circadian_calc(percept_data_VCVS,2,2,[],1);
% %     percept_data1day_VCVS = circadian_calc(percept_data_VCVS,0,0,[],1);
% %     percept_data_VCVS.entropy = percept_data1day_VCVS.entropy;
% %     save(strcat(loaddir,'demo_data_prepped_VCVS.mat'),"percept_data_VCVS","zone_index_VCVS");
% %     save(strcat(loaddir,'demo_data_prepped1day_VCVS.mat'),"percept_data1day_VCVS","zone_index_VCVS");
% % 
% % end

if exist("percept_data_GPi")
    percept_data_GPi = circadian_calc(percept_data_GPi,2,2,[],1);
    percept_data1day_GPi = circadian_calc(percept_data_GPi,0,0,[],1);
    percept_data_GPi.entropy = percept_data1day_GPi.entropy;
    save(strcat(loaddir,'demo_data_prepped_GPi.mat'),"percept_data_GPi","zone_index_GPi");
    save(strcat(loaddir,'demo_data_prepped1day_GPi.mat'),"percept_data1day_GPi","zone_index_GPi");
end
toc