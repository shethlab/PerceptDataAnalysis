%% This function is used to create heatmaps of normalized LFP vs time of
% day vs days since DBS on. This function has three required inputs and one
% optional:
%   1. percept_data: the data structure containing the Percept data. This 
%       structure must contain two fields called "days" and
%       "LFP_norm_matrix." This structure is generated as part of the
%       generate_data function.
%   2. hemisphere: the hemisphere of data to display. Set to 1 for left or
%       2 for right.
%   3. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   5 (optional). is_demo: a flag which, when set to 1, signals that the
%       demo dataset (demo_data.mat) is being run. This plots only the
%       first five patients to align with the patients displayed in the
%       manuscript Figure 2 and S1.
%
% This function outputs an n x 1 plot of cosinor amplitude (radial axis) vs
% acrophase (angular axis), where n is the number of subjects. Points
% corrseponding to days which resulted in non-significant cosinor fits are
% plotted with reduced transparency.

function plot_heatmap(data,hemisphere,zone_index,is_demo)

%% Detailed Adjustable Inputs

x_tick_scale = 20; % Distance between x ticks
fontsize = 8; % Font size
colorbar_height = 0.015; % Colorbar height (fraction of figure size of all combined)
colorbar_offset = 0.175; % Vertical offset of colorbar from heatmaps (fraction of figure size of all combined)
heatmap_height = 0.575; % Heatmap height (fraction of figure size of all combined)
horiz_space_bw_plots = 0.005; % Horizontal gap between bars/spectrograms (fraction of figure size)
width_scale = 0.8; % Fraction of figure width occupied by plots
colormap_limits = [-1,7]; % Lower and upper value cutoffs for the heatmap jet color scheme
zero_day_line_thickness = 2; % Thickness of dotted line denoting x=0
fig_height = 3; % Figure height in cm
fig_width = 18.5; % Figure width in cm

%Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [127,63,152]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone

%% Plotting

if exist('is_demo','var') && is_demo == 1 % For figure 2 & S1 demo
    total_height = 5;
else
    total_height = size(percept_data.days,1);
end

figure('Units','centimeters','Position',[0,0,fig_width,fig_height*total_height],'Color','w');

%Determine maximum number of data points to display horizontally
max_day_width = max(cellfun('length',data.days(:,hemisphere+1)));
colorbar_height = colorbar_height/size(data.days,1); % Colorbar height (fraction of figure size)
colorbar_offset = colorbar_offset/size(data.days,1); % Vertical offset of colorbar from heatmaps (fraction of figure size)
heatmap_height = heatmap_height/size(data.days,1); % Heatmap height (fraction of figure size)

for j = 1:size(data.days,1)
    
    %Temporary variables per iteration
    LFP = data.LFP_norm_matrix{j,hemisphere+1};
    days = data.days{j,hemisphere+1}; 

    %Find indices of discontiuous days of data
    start_index = find(diff(days)>1);
    try
        start_index = [1,start_index+1];
    catch
        start_index = 1;
    end
    subplot_number = length(start_index);
    
    %Find indices of each zone
    pre_DBS_idx = find(days<0);
    try
        [~,non_responder_idx] = intersect(days,zone_index.non_responder{j});
        [~,responder_idx] = intersect(days,zone_index.responder{j});
        [~,manic_idx] = intersect(days,zone_index.hypomania{j});
    catch
        disp('Invalid zone index labels. Using default color labels.')
        non_responder_idx = [];
        responder_idx = [];
        manic_idx = [];
    end
    
    %Generate RGB colormap for each index of data
    c_map = ones(length(days),3);
    c_map(pre_DBS_idx,:) = repmat(c_preDBS,[length(pre_DBS_idx),1]);
    c_map(responder_idx,:) = repmat(c_responder,[length(responder_idx),1]);
    c_map(non_responder_idx,:) = repmat(c_nonresponder,[length(non_responder_idx),1]);
    c_map(manic_idx,:) = repmat(c_mania,[length(manic_idx),1]);
    
    %Colorbar plot
    for i = 1:subplot_number %Split up discontinuous data into multiple plots with small gaps between
        if i == 1 && i ~= subplot_number %First of multiple plots
            ax1{i} = subplot(2*size(data.days,1),1,j*2-1);
            imagesc([days(start_index(i)),days(start_index(i+1)-1)],[],1:start_index(i+1)-start_index(i)); %plot subplot heatmap
            colormap(ax1{i},c_map(start_index(i):start_index(i+1)-1,:)) %apply colormap
            xlim([days(start_index(i))-.5,days(start_index(i+1)-1)+.5]) %stretch data to fill plot width
            ax1{i}.Position(3) = width_scale/max_day_width*ax1{i}.DataAspectRatio(1); %rescale subplot width relative to figure size
        elseif i == 1 && i == subplot_number %First and last plot
            ax1{i} = subplot(2*size(data.days,1),1,j*2-1);
            imagesc([days(start_index(i)),days(end)],[],1:length(days)-start_index(i));
            colormap(ax1{i},c_map(start_index(i):end,:));
            xlim([days(start_index(i))-.5,days(end)+.5])
            ax1{i}.Position(3) = width_scale/max_day_width*ax1{i}.DataAspectRatio(1);
        elseif i == subplot_number %Last of multiple plots
            ax1{i} = axes('Position',[ax1{i-1}.Position(1)+ax1{i-1}.Position(3)+horiz_space_bw_plots,ax1{i-1}.Position(2),width_scale/max_day_width*(length(days)-start_index(i)),colorbar_height]);
            imagesc([days(start_index(i)),days(end)],[],1:length(days)-start_index(i));
            colormap(ax1{i},c_map(start_index(i):end,:));
            xlim([days(start_index(i))-.5,days(end)+.5])
        else %Middle of multiple plots
            ax1{i} = axes('Position',[ax1{i-1}.Position(1)+ax1{i-1}.Position(3)+horiz_space_bw_plots,ax1{i-1}.Position(2),width_scale/max_day_width*(start_index(i+1)-start_index(i)-1),colorbar_height]);
            imagesc([days(start_index(i)),days(start_index(i+1)-1)],[],1:start_index(i+1)-start_index(i));
            colormap(ax1{i},c_map(start_index(i):start_index(i+1)-1,:))
            xlim([days(start_index(i))-.5,days(start_index(i+1)-1)+.5])        
        end
        set(gca,'Visible','off','Color','none')
        ax1{i}.Position(4) = colorbar_height; %sets colorbar height to user spec
    end
    
    %Heatmap plot
    for i = 1:subplot_number %Split up discontinuous data into multiple plots with small gaps between
        if i == 1 && i ~= subplot_number %First of multiple plots
            ax2{i} = subplot(2*size(data.days,1),1,j*2);
            imagesc([days(start_index(i)),days(start_index(i+1)-1)],[],LFP(:,start_index(i):start_index(i+1)-1));
            xticks = x_tick_scale*ceil(days(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(days(start_index(i+1)-1)/x_tick_scale);
            ax2{i}.Position(3) = width_scale/(max_day_width/2)*ax2{i}.DataAspectRatio(1);
        elseif i == 1 && i == subplot_number %First and last plot
            ax2{i} = subplot(2*size(data.days,1),1,j*2);
            imagesc([days(start_index(i)),days(end)],[],LFP(:,start_index(i):end));
            xticks = x_tick_scale*ceil(days(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(days(end)/x_tick_scale);
            ax2{i}.Position(3) = width_scale/(max_day_width/2)*ax2{i}.DataAspectRatio(1);
        elseif i == subplot_number %Last of multiple plots
            ax2{i} = axes('Position',[ax2{i-1}.Position(1)+ax2{i-1}.Position(3)+horiz_space_bw_plots,ax2{i-1}.Position(2),width_scale/max_day_width*(length(days)-start_index(i)),heatmap_height]);
            imagesc([days(start_index(i)),days(end)],[],LFP(:,start_index(i):end));
            xticks = x_tick_scale*ceil(days(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(days(end)/x_tick_scale);
        else %Middle of multiple plots
            ax2{i} = axes('Position',[ax2{i-1}.Position(1)+ax2{i-1}.Position(3)+horiz_space_bw_plots,ax2{i-1}.Position(2),width_scale/max_day_width*(start_index(i+1)-start_index(i)-1),heatmap_height]);
            imagesc([days(start_index(i)),days(start_index(i+1)-1)],[],LFP(:,start_index(i):start_index(i+1)-1));
            xticks = x_tick_scale*ceil(days(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(days(start_index(i+1)-1)/x_tick_scale);
        end
        
        %Adds a vertical line at the zero point
        xline(0,'--y','LineWidth',zero_day_line_thickness,'Alpha',1)

        %Sets the colormap to "jet" and map limits to user spec
        colormap(ax2{i},jet)
        clim(colormap_limits)
        
        %Plot y-axis labels on first plot
        if i==1
            yticks = [0.5,36:36:144];
            yticklabels = {'0:00','','12:00','','24:00'};            
            set(gca,'YTick',yticks,'YTickLabels',yticklabels,'TickLength',[0.01,0.01],'FontSize',fontsize);
            ylabel(data.LFP_norm_matrix(j,1))
        else
            set(gca,'YTick',[]);
        end
        
        %X-axis diagonal labels
        set(gca,'LineWidth',0.1,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',fontsize)
        xtickangle(45)
       
        ax2{i}.Position(4) = heatmap_height; %sets heatmap height to user spec
        ax1{i}.Position(2) = ax1{i}.Position(2)+colorbar_offset; %shifts colorbar vertically to user spec 
    end
end

end