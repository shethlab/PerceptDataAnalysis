%% This function is used to calculate significance of distributions of
% various metrics before vs after DBS as well as stationarity using the
% Augmented Dickey-Fuller (ADF) and Kwiatkowski–Phillips–Schmidt–Shin (KPSS)
% test. Metrics include cosinor R2, amplitude, and acrophase; linearAR R2; 
% nonlinear AR R2; and sample entropy. This function has three required 
% inputs and one optional:
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
%   4. effective (optional): a binary (0 or 1) input for deciding whether to use
%       Effective Sample Size (ESS) for statistical tests. ESS accounts for
%       underlying autocorrelation. Defaults to 0 if not provided.
%
% This function has two outputs:
%   1. ttest: a 1x2 cell array (one for each hemisphere) containing a
%       structure containing the following results of the t-test: p-value,
%       t-statistic, 95% confidence interval, degrees of freedom, Hedge's
%       g, Hedge's g 95% confidence interval, and sample sizes.
%   2. stationarity: a 1x2 cell array (one for each hemisphere) containing
%       a 2x2 table with the results of the ADF and KPSS tests for each of
%       the two groups being compared.

function [ttest,stationarity] = calc_significance(percept_data,field,zone_index,effective) 

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

if ~exist('effective','var') || ~isnumeric(effective) || isempty(effective) || effective ~= 1
    effective = 0;
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
        stats{j,hemisphere} = detailedStats(pre_DBS_data(~isnan(pre_DBS_data)),chronic_data(~isnan(chronic_data)),percept_data.days{j,1},effective);
        
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