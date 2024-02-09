%% This function is used to save various data metrics in a single subject to
% a video as described in Provenza, Reddy, and Allam et al. 2024. Metrics 
% include cosinor R2, linear autoregressive R2, and sample entropy. 
% This function has five required inputs and one optional:
%   1. f_name: filename to save the output mp4 video as.
%   2. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is something.py, which creates the
%       appropriately-formatted data structure. This structure must contain
%       fields called "days," "LFP_raw_matrix," "cosinor_R2," "linear_AR_R2," 
%       and "entropy."
%   3. subject: the name of the subject to load as a string. This name
%       should match the appropriate data row in percept_data.days.
%   4. hemisphere: the hemisphere of data to display. Set to 1 for left or
%       2 for right.
%   5. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   6. x_scale (optional): can be "static" (constant x-axis scale) or
%       "dynamic" (x-axis expands to fit new data). Defaults to "static" if
%       no input is provided.
%
% This function saves a video in the format of Supplemental Videos 1 & 2 
% from the main manuscript. The top row contains a zoomed, rotated
% "template" of any particular day. The bottom three rows show the cosinor
% R2, linear AR R2, and sample entropy values corresponding to that
% particular day.

function plot_video(f_name,percept_data,subject,hemisphere,zone_index,x_scale)

%% Detailed inputs
pre_DBS_FPS = 3; %frames per second
post_DBS_FPS = 20; %frames per second

x_tick_scale = 50;
pos = [0,0,1920,1080]; % please keep this in a 16:9 aspect ratio
tick_height = [0.005,0.005]; % x and y tick height
EMA_window = 5; %number of days for exponential moving average (EMA)
EMA_skip = 2; %number of initial data points to skip in EMA to avoid tails
sz = 20; %dot sizes
EMA_sz = 3; %line width for EMA
patch_alpha = 0.3; % Transparency for background colors

ylim_LFP = [-2,6]; % Radial limits for the polar daily templates
ylim_R2 = [-30,90]; % Y axis limits for the cosinor/linear AR R2 over time plots
ylim_SE = [0,0.08]; % Y axis limits for the sample entropy over time plots

fontsize_polar = 25; % Fontsize of polar plot labels
fontsize_ylabel = 18; % Font size of cartesian plot y-labels
fontsize_axes = 14; % Font size of cartesian plot axes numbers

%Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [255,185,0]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone
c_dots = [0.5,0.5,0.5]; % Color of scatter plot
c_EMA = [0,0,0]; % Color of EMA line
c_linAR = [51,160,44]/255; % Color of linear AR label
c_cosinor = [251,154,153]/255; % Color of cosinor label
c_SE = [106,61,154]/255; % Color of sample entropy label

%% Main plotting code
try
    patient_idx = find(contains(percept_data.days(:,1),subject));
    patient_idx(1);
catch
    error('Subject not found in structure.')
end

if ~exist('x_scale','var') || ~strcmpi(x_scale,'dynamic')
    x_scale = 'static';
end

max_FPS = max([pre_DBS_FPS,post_DBS_FPS]);
v = VideoWriter(f_name,'MPEG-4');
v.FrameRate = max_FPS;
open(v)
fig = figure('Position',pos,'Color','w');
tiledlayout(10,1);

% Data variables
days = percept_data.days{patient_idx,hemisphere+1}; % This vector may be edited as the code proceeds
raw = percept_data.LFP_raw_matrix{patient_idx,hemisphere+1};
raw_filled = decibelize(fillData(raw,days));

cosinor_R2 = percept_data.cosinor_R2{patient_idx,hemisphere+1};
linAR_R2 = percept_data.linearAR_R2{patient_idx,hemisphere+1};
SE = percept_data.entropy{patient_idx,hemisphere+1};

xticks = x_tick_scale*ceil(min(days)):x_tick_scale:x_tick_scale*floor(max(days));

%Find indices of each zone
pre_DBS_idx = find(days<0);
try
    [~,non_responder_idx] = intersect(days,zone_index.non_responder{patient_idx});
    [~,responder_idx] = intersect(days,zone_index.responder{patient_idx});
    [~,manic_idx] = intersect(days,zone_index.hypomania{patient_idx});
catch
    disp('Invalid zone index labels. Using default color labels.')
    non_responder_idx = [];
    responder_idx = [];
    manic_idx = [];
end

%Generate RGB colormap for each index of data
c_map = 0.5*ones(length(days),3);
c_map(pre_DBS_idx,:) = repmat(c_preDBS,[length(pre_DBS_idx),1]);
c_map(responder_idx,:) = repmat(c_responder,[length(responder_idx),1]);
c_map(non_responder_idx,:) = repmat(c_nonresponder,[length(non_responder_idx),1]);
c_map(manic_idx,:) = repmat(c_mania,[length(manic_idx),1]);

% Calculate EMA prior to looping for speed purposes
cosinor_EMA = EMA_calc(days,cosinor_R2,EMA_window,EMA_skip);
linAR_EMA = EMA_calc(days,linAR_R2,EMA_window,EMA_skip);
SE_EMA = EMA_calc(days,SE,EMA_window,EMA_skip);

for a = 1:length(days)     
    nexttile(1,[4,1])
    polarplot(0:2*pi/144:2*pi*143/144,raw_filled(:,a),'Color',c_map(a,:),'LineWidth',2)
    
    pax = gca;
    set(pax,'ThetaDir','clockwise','ThetaZeroLocation','top','FontSize',fontsize_polar,'RTickLabels',[],'FontName','Myriad Pro')
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
    pax.LineWidth=1.5;
    rlim([min(min(raw_filled)),6])
    
    nexttile(5,[2,1])
    cla reset
    hold on
    patches(patient_idx,zone_index,patch_alpha,c_preDBS,c_mania,c_responder,c_nonresponder)
    scatter(days(1:a),100*cosinor_R2(1:a),sz,c_dots,'filled')
    plot(days(1:a),100*cosinor_EMA(1:a),'Color',c_EMA,'LineWidth',EMA_sz)
    if strcmpi(x_scale,'static')
        xlim([min(days),max(days)])
    elseif strcmp(x_scale,'dynamic')
        xlim([min(days),days(a)+1])
    end
    ylim(ylim_R2)
    set(gca,'TickLength',tick_height,'FontName','Myriad Pro','FontSize',fontsize_axes)
    ylabel('Cosinor R^2 (%)',FontSize=fontsize_ylabel,Color=c_cosinor)
    hold off
    
    nexttile(7,[2,1])
    cla reset
    hold on
    patches(patient_idx,zone_index,patch_alpha,c_preDBS,c_mania,c_responder,c_nonresponder)
    scatter(days(1:a),100*linAR_R2(1:a),sz,c_dots,'filled')
    plot(days(1:a),100*linAR_EMA(1:a),'Color',c_EMA,'LineWidth',EMA_sz)
    if strcmpi(x_scale,'static')
        xlim([min(days),max(days)])
    elseif strcmp(x_scale,'dynamic')
        xlim([min(days),days(a)+1])
    end
    ylim(ylim_R2)
    set(gca,'TickLength',tick_height,'FontName','Myriad Pro','FontSize',fontsize_axes)
    ylabel('Linear AR R^2 (%)',FontSize=fontsize_ylabel,Color=c_linAR)
    hold off
    
    nexttile(9,[2,1])
    cla reset
    hold on
    patches(patient_idx,zone_index,patch_alpha,c_preDBS,c_mania,c_responder,c_nonresponder)
    scatter(days(1:a),SE(1:a),sz,c_dots,'filled')
    plot(days(1:a),SE_EMA(1:a),'Color',c_EMA,'LineWidth',EMA_sz)
    if strcmpi(x_scale,'static')
        xlim([min(days),max(days)])
    elseif strcmp(x_scale,'dynamic')
        xlim([min(days),days(a)+1])
    end
    ylim(ylim_SE)
    set(gca,'TickLength',tick_height,'FontName','Myriad Pro','FontSize',fontsize_axes)
    ax = gca;
    ax.YAxis.Exponent = -1;
    ylabel('Sample Entropy',FontSize=fontsize_ylabel,Color=c_SE)
    xlabel('Days Since DBS On',FontSize=fontsize_ylabel)
    hold off
    
    %Save frames to video
    F = getframe(fig);
    if intersect(pre_DBS_idx,a) % Current day is pre-DBS
        F = repelem(F,round(max_FPS/pre_DBS_FPS)); % Use pre-DBS FPS
    else
        F = repelem(F,round(max_FPS/post_DBS_FPS)); % Use post-DBS FPS
    end
    writeVideo(v,F);
end

close(v)
close(fig)

end

%%

function EMA_LFP = EMA_calc(days,stat,EMA_window,EMA_skip)
    EMA_LFP = nan(1,length(days));

    start_index = find(diff(days)>1);
    if ~isempty(start_index)
        start_index = [1, start_index+1, length(days)+1];
    else
        start_index = [1;length(days)+1];
    end

    for i = 1:length(start_index)-1
        skip_idx = max([EMA_skip,find(~isnan(stat(start_index(i):end)),1,'first')]); %Skip 1st data point or initial NaN points when identifying start of EMA
        ind = start_index(i)+skip_idx-1:start_index(i+1)-1;
        try
            temp_days = (days(ind));
            temp_EMA = movavg(filloutliers(fillmissing(stat(ind),'pchip','EndValues','none')','pchip'),"exponential",EMA_window)';
            [~,idx] = intersect(days,temp_days);
            EMA_LFP(idx) = temp_EMA;
        end
    end
end

function patches(patient_idx,zone_index,patch_alpha,c_preDBS,c_mania,c_responder,c_nonresponder)
    try
        if ~isempty(zone_index.hypomania{patient_idx}) %Hypomania zone
            zone_idx = [0,find(diff(zone_index.hypomania{patient_idx})>1),length(zone_index.hypomania{patient_idx})];
            for i = 1:length(zone_idx)-1
                patch([zone_index.hypomania{patient_idx}(zone_idx(i)+1),zone_index.hypomania{patient_idx}(zone_idx(i)+1),zone_index.hypomania{patient_idx}(zone_idx(i+1))+1,zone_index.hypomania{patient_idx}(zone_idx(i+1))+1],[-100,100,100,-100],c_mania,'FaceAlpha',patch_alpha,'LineStyle','none')
            end
        end    
        if ~isempty(zone_index.responder{patient_idx}) %Responder zone
            zone_idx = [0,find(diff(zone_index.responder{patient_idx})>1),length(zone_index.responder{patient_idx})];
            for i = 1:length(zone_idx)-1
                patch([zone_index.responder{patient_idx}(zone_idx(i)+1),zone_index.responder{patient_idx}(zone_idx(i)+1),zone_index.responder{patient_idx}(zone_idx(i+1))+1,zone_index.responder{patient_idx}(zone_idx(i+1))+1],[-100,100,100,-100],c_responder,'FaceAlpha',patch_alpha,'LineStyle','none')
            end
        end        
        if ~isempty(zone_index.non_responder{patient_idx}) %Non-responder zone
            zone_idx = [0,find(diff(zone_index.non_responder{patient_idx})>1),length(zone_index.non_responder{patient_idx})];
            for i = 1:length(zone_idx)-1
                patch([zone_index.non_responder{patient_idx}(zone_idx(i)+1),zone_index.non_responder{patient_idx}(zone_idx(i)+1),zone_index.non_responder{patient_idx}(zone_idx(i+1))+1,zone_index.non_responder{patient_idx}(zone_idx(i+1))+1],[-100,100,100,-100],c_nonresponder,'FaceAlpha',patch_alpha,'LineStyle','none')
            end
        end
    catch
        disp('Invalid zone index labels. Using default color labels.')
    end
    patch([-999,-999,0,0],[-100,100,100,-100],c_preDBS,'FaceAlpha',patch_alpha,'LineStyle','none') %Pre-DBS zones
end