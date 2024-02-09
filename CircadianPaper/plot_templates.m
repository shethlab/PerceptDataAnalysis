%% This function is used to create circular polar plots of LFP values vs
% time of day. This function has four required inputs and one optional:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this function is the circadian_calc function, which
%       creates the appropriately-formatted data structure. This structure 
%       must contain four fields called "days," "template_acro," "template_p,"
%       and "LFP_raw_matrix."
%   2. subject: the name of the subject to load as a string. This name
%       should match the appropriate data row in percept_data.days.
%   3. hemisphere: the hemisphere of data to display. Set to 1 for left or
%       2 for right.
%   3. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   5 (optional). template_days: a vector containing a list of days
%       (expressed as integer days since DBS activation) for which to plot
%       circular templates. If left blank, only the average zone template
%       will be displayed.
%
% This function outputs an 1x(n+1) plot of cosinor amplitude (radial axis) vs
% acrophase (angular axis), where n is the number of inputted template days. 
% The final plot is an overlay of median-averaged templates in the pre-DBS
% zone and the chronic clinical state zone.

function plot_templates(percept_data,subject,hemisphere,zone_index,template_days)

%% Detailed adjuatable inputs

% Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [255,185,0]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone

fig_width = 4; % Width of figure in cm per template (will be multiplied by number of templates)
fig_height = 4; % Height of figure in cm
%% Importing data

try
    patient_idx = find(contains(percept_data.days(:,1),subject));
    patient_idx(1);
catch
    error('Subject not found in structure.')
end

days = percept_data.days{patient_idx,hemisphere+1};
acrophases = percept_data.template_acro{patient_idx,hemisphere+1}(:,:,1);
p_vals = percept_data.template_p{patient_idx,hemisphere+1};

logged_data = decibelize(fillData(percept_data.LFP_raw_matrix{patient_idx,hemisphere+1},days));

%% Single Day Templates

if ~exist('template_days','var') || ~isnumeric(template_days) || isempty(template_days) || isempty(intersect(template_days,days))
    disp('No or invalid single day indices provided. Plotting average templates only.')
    figure('Units','centimeters','Position',[0,0,fig_width,fig_height],'Color','w');
else
    figure('Units','centimeters','Position',[0,0,fig_width*length(template_days)+1,fig_height],'Color','w');
    tiledlayout(1,length(template_days)+1)
    unsmoothed_data = smoothRotate(logged_data,acrophases,p_vals,0); % Don't apply Gaussian smoothing for daily
    
    % Find indices of each zone
    pre_DBS_idx = find(days<0);
    try
        [~,non_responder_idx] = intersect(days,zone_index.non_responder{patient_idx});
        [~,responder_idx] = intersect(days,zone_index.responder{patient_idx});
        [~,manic_idx] = intersect(days,zone_index.hypomania{patient_idx});
    catch
        non_responder_idx = [];
        responder_idx = [];
        manic_idx = [];
    end
        
    for i = 1:length(template_days)
        nexttile
        day_idx = find(days == template_days(i));
        
        if intersect(day_idx,pre_DBS_idx)
            plot_color = c_preDBS;
        elseif intersect(day_idx,responder_idx)
            plot_color = c_responder;
        elseif intersect(day_idx,non_responder_idx)
            plot_color = c_nonresponder;
        elseif intersect(day_idx,manic_idx)
            plot_color = c_mania;
        else %provided day out of range
            disp('A provided template day is out of the data range. Skipping.')
            polarPlotDay(nan,unsmoothed_data,plot_color);
        end
        
        polarPlotDay(unsmoothed_data(:,day_idx),unsmoothed_data,plot_color);
    end
end

%% Average Templates

smoothed_data = smoothRotate(logged_data,acrophases,p_vals,1); % Apply Gaussian smoothing for averages

% Find indices of each zone
pre_DBS_idx = find(days<0);
try
    [~,non_responder_idx] = intersect(days,zone_index.non_responder{patient_idx});
    [~,responder_idx] = intersect(days,zone_index.responder{patient_idx});
    [~,manic_idx] = intersect(days,zone_index.hypomania{patient_idx});
catch
    non_responder_idx = [];
    responder_idx = [];
    manic_idx = [];
end

% Remove days with non-significant cosinor fits from average templates
pre_DBS_idx = setdiff(pre_DBS_idx,find(isnan(acrophases)));
responder_idx = setdiff(responder_idx,find(isnan(acrophases)));
non_responder_idx = setdiff(non_responder_idx,find(isnan(acrophases)));
manic_idx = setdiff(manic_idx,find(isnan(acrophases)));

pre_DBS_data = median(smoothed_data(:,pre_DBS_idx),2,'omitnan');
responder_data = median(smoothed_data(:,responder_idx),2,'omitnan');
non_responder_data = median(smoothed_data(:,non_responder_idx),2,'omitnan');
manic_data = median(smoothed_data(:,manic_idx),2,'omitnan');

nexttile
polarPlotDay(pre_DBS_data,smoothed_data,c_preDBS)
hold on
polarPlotDay(responder_data,smoothed_data,c_responder)
polarPlotDay(non_responder_data,smoothed_data,c_nonresponder)
polarPlotDay(manic_data,smoothed_data,c_mania)
hold off

end