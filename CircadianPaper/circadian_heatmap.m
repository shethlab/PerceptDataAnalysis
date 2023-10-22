function [] = circadian_heatmap(data,hemisphere,zone_index)

%% Detailed Adjustable Inputs

x_tick_scale = 20; % Distance between x ticks
fontsize = 8; % Font size
colorbar_height = 0.003; % Colorbar height (fraction of figure size)
colorbar_offset = 0.035; % Vertical offset of colorbar from heatmaps (fraction of figure size)
heatmap_height = 0.115; % Heatmap height (fraction of figure size)
horiz_space_bw_plots = 0.005; % Horizontal gap between bars/spectrograms (fraction of figure size)
width_scale = 0.8; % Fraction of figure width occupied by plots
colormap_limits = [-1,7]; % Lower and upper value cutoffs for the heatmap jet color scheme
zero_day_line_thickness = 2; % Thickness of dotted line denoting x=0
fig_position = [0 0 5.9 7.3]; % Position of figure in inches

%Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [127,63,152]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone

% Stimulation change lines
include_stim_changes = false; 

%% Plotting

figure('Units','inches','Position',fig_position);

%Determine maximum number of data points to display horizontally
max_day_width = max(cellfun('length',data.days(:,hemisphere+1)));

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

    % Find when stimulation is changed day to day
    if include_stim_changes == 1
        % find the maximum daily stimulation
        stim_matrix = cell2mat(data.stim_matrix(j,hemisphere+1));
        max_daily_stim = max(stim_matrix, [], 1, 'omitnan');

        % when the stimulation changes
        stim_diffs = diff(max_daily_stim);
        change_indices = find(stim_diffs) + 1;
    end
    
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

        % Add lines where the stimulation was changed
        if include_stim_changes == 1
            days = cell2mat(data.days(j, hemisphere+1));
            days_to_plot = days(change_indices);
            days_to_plot = days_to_plot(days_to_plot >= 1);

            xline(days_to_plot, '-.m', 'LineWidth', zero_day_line_thickness, 'Alpha', 1)
        end
        
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