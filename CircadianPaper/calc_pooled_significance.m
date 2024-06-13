%% This function is used to calculate significance of distributions of
% various metrics pooled across all patients in the symptomatic (i.e. pre-DBS
% and chronic non-responder) vs responder (i.e. post-DBS chronic responder) 
% states. Metrics include cosinor R2, amplitude, and acrophase; linearAR R2; 
% nonlinear AR R2; and sample entropy. This function has two required inputs 
% and one optional:
%   1. percept_data: the data structure containing the Percept data. The
%      prerequisite for this code is calc_circadian.py, which creates the
%      appropriately-formatted data structure. This structure must contain
%      fields called "zone index" and any of the following: "cosinor_R2,"
%      "amplitude," "acrophase," "linear_AR_R2," "nonlinear_AR_R2" and 
%      "entropy."
%   2. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   3. effective (optional): a binary (0 or 1) input for deciding whether to use
%       Effective Sample Size (ESS) for statistical tests. ESS accounts for
%       underlying autocorrelation. Defaults to 0 if not provided.
%
% This function has one output:
%   1. ttest: a 1x2 cell array (one for each hemisphere) containing a
%       structure containing the following results of the t-test: p-value,
%       t-statistic, 95% confidence interval, degrees of freedom, Hedge's
%       g, Hedge's g 95% confidence interval, and sample sizes.

function ttest = calc_pooled_significance(percept_data,zone_index,effective) 

if isfield(percept_data,'nonlinearAR_R2') %List of models to analyze
    field = {'cosinor_R2','linearAR_R2','nonlinearAR_R2','entropy'};
else
    field = {'cosinor_R2','linearAR_R2','entropy'};
end

% Identify which metrics are provided in the data
field = field(isfield(percept_data,field));

if ~exist('effective','var') || ~isnumeric(effective) || isempty(effective) || effective ~= 1
    effective = 0;
end

for hemisphere = 1:2
    symptomatic_data_array = [];
    responder_data_array = [];
    ESS_symptomatic = zeros(1,4);
    ESS_responder = zeros(1,4);
    
    for j = 1:size(percept_data.days,1)
        preDBS_data = [];
        nonresponder_data = [];
        symptomatic_data = [];
        responder_data = [];
        model_preDBS_data = {};
        model_nonresponder_data = {};
        model_symptomatic_data = {};
        model_responder_data = {};

        % Find zone indices relative to days since DBS activation
        days = percept_data.days{j,hemisphere+1};
        [~,preDBS_idx] = intersect(days,days(days < 0));
        [~,nonresponder_idx] = intersect(days,zone_index.non_responder{j});
        [~,symptomatic_idx] = intersect(days,[days(days < 0),zone_index.non_responder{j}]);
        [~,responder_idx] = intersect(days,zone_index.responder{j});
    
        for m = 1:length(field)            
            % Extract per-zone data
            model_preDBS_data{m} = percept_data.(field{m}){j,hemisphere+1}(1,preDBS_idx,1);
            model_nonresponder_data{m} = percept_data.(field{m}){j,hemisphere+1}(1,nonresponder_idx,1);
            model_symptomatic_data{m} = percept_data.(field{m}){j,hemisphere+1}(1,symptomatic_idx,1);
            model_responder_data{m} = percept_data.(field{m}){j,hemisphere+1}(1,responder_idx,1);
            
            % Add current patient's data to pooled data
            preDBS_data = [preDBS_data,model_preDBS_data{m}'];
            nonresponder_data = [nonresponder_data,model_nonresponder_data{m}'];
            symptomatic_data = [symptomatic_data,model_symptomatic_data{m}'];
            responder_data = [responder_data,model_responder_data{m}'];
        end

        % Deleting days with NaN for any metric to match sample sizes across metrics
        preDBS_nan_index = find(any(isnan(preDBS_data),2));
        preDBS_data(preDBS_nan_index,:) = [];        
        
        nonresponder_nan_index = find(any(isnan(nonresponder_data),2));
        nonresponder_data(nonresponder_nan_index,:) = [];
        
        symptomatic_nan_index = find(any(isnan(symptomatic_data),2));
        symptomatic_data(symptomatic_nan_index,:) = [];
        
        responder_nan_index = find(any(isnan(responder_data),2));
        responder_data(responder_nan_index,:) = [];

        symptomatic_data_array = [symptomatic_data_array;symptomatic_data];
        responder_data_array = [responder_data_array;responder_data];
        
        % Adding effective sample size to running tally
        for m = 1:length(field)
            ESS_symptomatic(m) = ESS_symptomatic(m) + ESS(preDBS_data(:,m)) + ESS(nonresponder_data(:,m));
            ESS_responder(m) = ESS_responder(m) + ESS(responder_data(:,m));
        end
    end

    for m = 1:length(field)
        % Comparing pre-DBS vs chronic state statistics
        if effective == 1 %If using effective sample size
            stats{m,hemisphere} = detailedStatsPooled(symptomatic_data_array(:,m),responder_data_array(:,m),field{m},ESS_symptomatic(m),ESS_responder(m));
        else %If using standard sample size
            stats{m,hemisphere} = detailedStatsPooled(symptomatic_data_array(:,m),responder_data_array(:,m),field{m},[],[]);
        end
    end
    
    ttest{hemisphere} = [stats{:,hemisphere}];
end

end