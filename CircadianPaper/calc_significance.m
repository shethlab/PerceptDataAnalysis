%% This function is used to calculate significance of distributions of
% various metrics before vs after DBS as well as stationarity. Metrics 
% include cosinor R2, amplitude, and acrophase; linearAR R2; nonlinear AR R2;
% and sample entropy. This function has three required inputs:
%   1. percept_data: the data structure containing the Percept data. The
%      prerequisite for this code is calc_circadian.py, which creates the
%      appropriately-formatted data structure. This structure must contain
%      fields called "zone index" and any of the following: "cosinor_R2,"
%      "amplitude," "acrophase," "linear_AR_R2," "nonlinear_AR_R2" and 
%      "entropy."
%   2. field: the name of the metric to perform calculations on - must be
%       one of the fields listed in input 1.
%   3. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%
% This function also requests inputs from the user through a command line
% prompt. It references the following two variables for each patient to be
% processed:
%   1. Cosinor components: the number of components (i.e. N in the cosinor
%       listed in the cosinor equation of the main manuscript).
%       Practically, this is the number of local maxima that appear during
%       each sinusoidal period, which can be determined visually or
%       calculated through a periodogram. Increasing the number of
%       components increases fit strength but results in overfitting if too
%       high a number is selected.
%   2. Cosinor peaks: the number of peaks for which to calculate amplitude
%       (peak height) and acrophase (time of the peak). This value must be
%       less than or equal to the number of components.
%
% This function has one output:
%   1. percept_data: the updated data structure including all of the input
%       information, as well as the new calculated data. New fields include
%       "entropy," "amplitude," "acrophase," and "cosinor_p." If the python
%       code is also processed, additional fields include "cosinor_R2,"
%       "cosinor_matrix," "linearAR_R2," "linearAR_matrix,"
%       "nonlinearAR_R2," "nonlinearAR_matrix," "ROC," and "kfold."

function [ttest,stationarity] = calc_significance(percept_data,field,zone_index) 

switch field
    case 'entropy'
    case 'amplitude'
    case 'acrophase'
    case 'cosinor_R2'
    case 'linearAR_R2'
    case 'nonlinearAR_R2'
    otherwise
        error('Inputted data field is invalid.')
end

for j = 1:size(percept_data.days,1)
    for hemisphere = 1:2      
        %Temporary variables per iteration
        days = percept_data.days{j,hemisphere+1};
        metric = percept_data.(field){j,hemisphere+1}(1,:,1);
        
        %Find zone indices
        pre_DBS_idx = days < 0;
        [~,chronic_idx] = intersect(days,[zone_index.responder{j},zone_index.non_responder{j}]);
        
        %Extract per-zone data
        pre_DBS_data = metric(1,pre_DBS_idx,1);
        chronic_data = metric(1,chronic_idx,1);
        
        %Comparing pre-DBS vs chronic state statistics
        stats{j,hemisphere} = detailedStats(pre_DBS_data(~isnan(pre_DBS_data)),chronic_data(~isnan(chronic_data)),percept_data.days{j,1});
        
        %Calculate stationarity for pre-DBS
        try
            [~,stationarity_preDBS{1,hemisphere}(j,2),stationarity_preDBS{1,hemisphere}(j,1)] = adftest(pre_DBS_data,model='AR');
            [~,stationarity_preDBS{2,hemisphere}(j,2),stationarity_preDBS{2,hemisphere}(j,1)] = kpsstest(pre_DBS_data);
        end

        %Calculate stationarity for post-DBS
        try
            [~,stationarity_chronic{1,hemisphere}(j,2),stationarity_chronic{1,hemisphere}(j,1)] = adftest(chronic_data,model='AR');
            [~,stationarity_chronic{2,hemisphere}(j,2),stationarity_chronic{2,hemisphere}(j,1)] = kpsstest(chronic_data);
        end
    end
end

%Convert stationarity from cells to tables
for hemisphere = 1:2
    try
        stationarity_preDBS{1,hemisphere} = array2table(stationarity_preDBS{1,hemisphere},'VariableNames',{'Pre-DBS Test Stat','Pre-DBS P-value'});
        stationarity_preDBS{2,hemisphere} = array2table(stationarity_preDBS{2,hemisphere},'VariableNames',{'Pre-DBS Test Stat','Pre-DBS P-value'});
    end
    try
        stationarity_chronic{1,hemisphere} = array2table(stationarity_chronic{1,hemisphere},'VariableNames',{'Post-DBS Test Stat','Post-DBS P-value'});
        stationarity_chronic{2,hemisphere} = array2table(stationarity_chronic{2,hemisphere},'VariableNames',{'Post-DBS Test Stat','Post-DBS P-value'});
    end
end

ttest{1}=[stats{:,1}];
ttest{2}=[stats{:,2}];

stationarity{1} = array2table([stationarity_preDBS(:,1),stationarity_chronic(:,1)],'VariableNames',{'Pre-DBS','Chronic Status'},'RowNames',{'ADF Test','KPSS Test'});
stationarity{2} = array2table([stationarity_preDBS(:,2),stationarity_chronic(:,2)],'VariableNames',{'Pre-DBS','Chronic Status'},'RowNames',{'ADF Test','KPSS Test'});

end