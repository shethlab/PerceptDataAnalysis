function metric_plot(percept_data,subject,hemisphere,pre_DBS_bounds,post_DBS_bounds,zone_index)

% Input descriptions:
% percept_data = name of percept_data structure
% subject = name of subject as described in data structure
% hemisphere = 1 (left) or 2 (right)
% pre_DBS_bounds = upper and lower bounds for zoomed-in plot in the form [A,B]
% post_DBS_bounds = upper and lower bounds for zoomed-in plot in the form [A,B]
% zone_index = name of zone_index structure

    %% Input parameter adjustments

    %Color values (RGB 0-1)
    c_mania = [255,0,0]/255; % Color of hypomania zone
    c_responder = [0,0,255]/255; % Color of chronic responder zone
    c_nonresponder = [255,185,0]/255; % Color of chronic non-responder zone
    c_preDBS = [255,215,0]/255; % Color of pre-DBS zone
    c_linAR = [213,62,79]/255; % Color of linear AR scatter plot/line
    c_cosinor = [252,141,89]/255; % Color of cosinor scatter plot/line
    c_SE = [0,0,64]/255; % Color of sample entropy scatter plot/line
    
    sz = 10; % Size of scatter plot dots
    ylim_LFP = [-2,6]; % Y axis limits for the zoomed-in time domain plots
    ylim_R2 = [0,90]; % Y axis limits for the cosinor/linear AR R2 over time plots
    ylim_SE = [0,0.05]; % Y axis limits for the sample entropy over time plots
    ema_skip = 3; % Number of points on the EMA line to skip at the beginning (use if there's large starting up/down tails)
    
    height_fullTD = 2; % relative height of full time-domain trace
    height_zoomTD = 3; % relative height of zoomed time-domain trace
    height_timeline = 1; % relative height of zone colorbar
    height_R2SE = 4; % relative height of R2/SE plots over time and violin plots
    
    font_size = 8; % Font size of numbers on axes 
    tick_size = 0.02; % Size of axis ticks
    
    fig_position = [0,0,30,20]; %dimensions of the figure (x location, y location, width, height)
    
    %% Main Plotting Code
    
    try
        patient_idx = find(contains(percept_data.days(:,1),subject));
        patient_idx(1);
    catch
        error('Subject not found in structure.')
    end

    days = percept_data.days{patient_idx,hemisphere+1}; % This vector may be edited as the code proceeds
    days_OG = days; % This vector will remain untouched
    t = percept_data.time_matrix{patient_idx,hemisphere+1};
    OG = percept_data.LFP_filled_matrix{patient_idx,hemisphere+1};
    cosinor = percept_data.cosinor_matrix{patient_idx,hemisphere+1};
    linAR = percept_data.linearAR_matrix{patient_idx,hemisphere+1};
    
    cosinor_R2 = percept_data.cosinor_R2{patient_idx,hemisphere+1};
    linAR_R2 = percept_data.linearAR_R2{patient_idx,hemisphere+1};
    SE = percept_data.entropy{patient_idx,hemisphere+1};
    
    figure('Units','centimeters','Position',fig_position);
    fig = tiledlayout(height_fullTD + height_zoomTD + height_timeline + 3*height_R2SE, 4);
    
    %Find indices of discontiuous days of data
    start_index = find(diff(days)>1);
    try
        start_index = [1,start_index,length(days)];
    catch
        start_index = [1,length(days)];
    end
    
    %Full time-domain plot w/discontinuous axes
    TD_tile = tiledlayout(fig,1,length(days_OG));
    TD_tile.Layout.TileSpan = [height_fullTD,3];
    for i = 1:length(start_index)-1
        TD(i) = nexttile(TD_tile,[1,start_index(i+1)-start_index(i)]);
        plot(t(:,start_index(i)+1:start_index(i+1)),OG(:,start_index(i)+1:start_index(i+1)),'Color',[0.5,0.5,0.5,0.5])
        xlim([min(t(:,start_index(i)+1:start_index(i+1)),[],'all'),max(t(:,start_index(i)+1:start_index(i+1)),[],'all')])
        if i == 1
            set(gca,'FontSize',font_size,'TickLength',[0.01,0.01]);
            ylabel('9 Hz LFP (mV)')
        else
            set(gca,'YTick',[],'FontSize',font_size,'TickLength',[0.01,0.01]);
        end
        box off
    end
    linkaxes(TD,'y')
    
    %Empty tile
    nexttile(fig,[height_fullTD,1]);
    set(gca,'Visible','off')
    
    %Pre-DBS zoom tile
    nexttile([height_zoomTD,2]);
    hold on
    plot(t(~isnan(t)),OG(~isnan(t)),'Color',[0.5,0.5,0.5,0.5],'LineWidth',2)
    plot(t(~isnan(t)),cosinor(~isnan(t)),'Color',c_cosinor,'LineWidth',2)
    plot(t(~isnan(t)),linAR(~isnan(t)),'Color',c_linAR,'LineWidth',1.5)
    xlim(pre_DBS_bounds)
    ylim(ylim_LFP)
    hold off
    set(gca,'LineWidth',2,'XColor',c_preDBS,'YColor',c_preDBS,'TickLength',[tick_size,0],'FontSize',font_size)
    ylabel('9 Hz LFP Amplitude (mV)','Color','k')
    legend({'Original','Cosinor','Linear AR'},Location="northeast")
    legend boxoff
    ax = gca;
    for i = 1:length(ax.XTickLabel)
        ax.XTickLabel{i} = ['\color{black}' ax.XTickLabel{i}];
    end
    for i = 1:length(ax.YTickLabel)
        ax.YTickLabel{i} = ['\color{black}' ax.YTickLabel{i}];
    end
    
    %Post-DBS zoom tile
    nexttile([height_zoomTD,2]);
    hold on
    plot(t(~isnan(t)),OG(~isnan(t)),'Color',[0.5,0.5,0.5,0.5],'LineWidth',2)
    plot(t(~isnan(t)),cosinor(~isnan(t)),'Color',c_cosinor,'LineWidth',2)
    plot(t(~isnan(t)),linAR(~isnan(t)),'Color',c_linAR,'LineWidth',1.5)
    xlim(post_DBS_bounds)
    ylim(ylim_LFP)
    hold off
    if ~isempty(zone_index.responder{patient_idx})
        set(gca,'LineWidth',2,'XColor',c_responder,'YColor',c_responder,'TickLength',[tick_size,0],'FontSize',font_size)
    else
        set(gca,'LineWidth',2,'XColor',c_nonresponder,'YColor',c_nonresponder,'TickLength',[tick_size,0],'FontSize',font_size)
    end
    ax = gca;
    for i = 1:length(ax.XTickLabel)
        ax.XTickLabel{i} = ['\color{black}' ax.XTickLabel{i}];
    end
    for i = 1:length(ax.YTickLabel)
        ax.YTickLabel{i} = ['\color{black}' ax.YTickLabel{i}];
    end
    box off
    
    %Timeline/colorbar tile w/discontinuity
    colorbar_tile = tiledlayout(fig,1,length(days_OG));
    colorbar_tile.Layout.TileSpan = [height_timeline,3];
    colorbar_tile.Layout.Tile = (height_fullTD + height_zoomTD)*4 + 1;
    
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
    c_map = ones(length(days),3);
    c_map(pre_DBS_idx,:) = repmat(c_preDBS,[length(pre_DBS_idx),1]);
    c_map(responder_idx,:) = repmat(c_responder,[length(responder_idx),1]);
    c_map(non_responder_idx,:) = repmat(c_nonresponder,[length(non_responder_idx),1]);
    c_map(manic_idx,:) = repmat(c_mania,[length(manic_idx),1]);
    
    for i = 1:length(start_index)-1 %Split up discontinuous data into multiple plots with small gaps between
        cb = nexttile(colorbar_tile,[1,start_index(i+1)-start_index(i)]);
        imagesc([days(start_index(i)+1),days(start_index(i+1))],[],1:start_index(i+1)-start_index(i));
        colormap(cb,c_map(start_index(i)+1:start_index(i+1),:))
        set(gca,'Visible','off','Color','none')
    end
    
    nexttile(fig,[height_timeline,1]);
    set(gca,'Visible','off')
    
    %Cosinor R2 plot w/discontinuities
    cosinor_tile = tiledlayout(fig,1,length(days_OG));
    cosinor_tile.Layout.TileSpan = [height_R2SE,3];
    cosinor_tile.Layout.Tile = (height_fullTD + height_zoomTD + height_timeline)*4 + 1;
    for i = 1:length(start_index)-1
        nexttile(cosinor_tile,[1,start_index(i+1)-start_index(i)]);
        hold on
        scatter(days(start_index(i)+1:start_index(i+1)),100*cosinor_R2(start_index(i)+1:start_index(i+1)),sz,'filled','MarkerFaceColor',c_cosinor,'MarkerFaceAlpha',0.3)
        EMA_plot(days(start_index(i)+1:start_index(i+1)),100*cosinor_R2(start_index(i)+1:start_index(i+1)),c_cosinor,ema_skip)
        xlim([min(days(start_index(i)+1:start_index(i+1)),[],'all'),max(days(start_index(i)+1:start_index(i+1)),[],'all')])
        ylim(ylim_R2)
        if i == 1
            set(gca,'FontSize',font_size,'TickLength',[tick_size,0]);
            ylabel('Cosinor R2 (%)')
        else
            set(gca,'YTick',[],'FontSize',font_size,'TickLength',[tick_size,0]);
        end
    end
    
    %Cosinor violin plot
    nexttile(fig,[height_R2SE,1]);
    if sum(days<0) == 0 %Add out-of-range values to allow plotting no data
        days(end+1) = -5;
        cosinor_R2(end+1) = -10;
        linAR_R2(end+1) = -10;
        SE(end+1) = -10;
    end
    if isempty([responder_idx,non_responder_idx]) %Add out-of-range values to allow plotting no data
        days(end+1) = 999;
        cosinor_R2(end+1) = -10;
        linAR_R2(end+1) = -10;
        SE(end+1) = -10;
        non_responder_idx = length(days);
    end
    group = [repelem({'Pre-DBS'},sum(days<0)),repelem({'Post-DBS'},length(non_responder_idx)+length(responder_idx))];
    data = [cosinor_R2(days<0)';cosinor_R2([responder_idx,non_responder_idx])'];
    if ~isempty(non_responder_idx)
        violinplot(100*data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');       
        violinplot(100*data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_nonresponder,'HalfViolin','right','QuartileStyle','shadow');       
    else
        violinplot(100*data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');
        violinplot(100*data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_responder,'HalfViolin','right','QuartileStyle','shadow');
    end
    set(gca,'XTick',[0.8,1.2],'XTickLabels',{'Pre-DBS','Chronic State'},'TickLength',[tick_size,0],'FontSize',font_size)
    xlim([0.5,1.5])
    ylim(ylim_R2)
    box off
    
    %Linear AR plot w/discontinuities
    linAR_tile = tiledlayout(fig,1,length(days_OG));
    linAR_tile.Layout.TileSpan = [height_R2SE,3];
    linAR_tile.Layout.Tile = (height_fullTD + height_zoomTD + height_timeline + height_R2SE)*4 + 1;
    for i = 1:length(start_index)-1
        nexttile(linAR_tile,[1,start_index(i+1)-start_index(i)]);
        hold on
        scatter(days(start_index(i)+1:start_index(i+1)),100*linAR_R2(start_index(i)+1:start_index(i+1)),sz,'filled','MarkerFaceColor',c_linAR,'MarkerFaceAlpha',0.3)
        EMA_plot(days(start_index(i)+1:start_index(i+1)),100*linAR_R2(start_index(i)+1:start_index(i+1)),c_linAR,ema_skip)
        xlim([min(days(start_index(i)+1:start_index(i+1)),[],'all'),max(days(start_index(i)+1:start_index(i+1)),[],'all')])
        ylim(ylim_R2)
        if i == 1
            set(gca,'FontSize',font_size,'TickLength',[tick_size,0]);
            ylabel('Linear AR R2 (%)')
        else
            set(gca,'YTick',[],'FontSize',font_size,'TickLength',[tick_size,0]);
        end
    end
    
    %Linear AR violin plot
    nexttile(fig,[height_R2SE,1]);
    group = [repelem({'Pre-DBS'},sum(days<0)),repelem({'Post-DBS'},length(non_responder_idx)+length(responder_idx))];
    data = [linAR_R2(days<0)';linAR_R2([responder_idx,non_responder_idx])'];
    if ~isempty(non_responder_idx)
        violinplot(100*data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');       
        violinplot(100*data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_nonresponder,'HalfViolin','right','QuartileStyle','shadow');       
    else
        violinplot(100*data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');
        violinplot(100*data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_responder,'HalfViolin','right','QuartileStyle','shadow');
    end
    set(gca,'XTick',[0.8,1.2],'XTickLabels',{'Pre-DBS','Chronic State'},'TickLength',[tick_size,0],'FontSize',font_size)
    xlim([0.5,1.5])
    ylim(ylim_R2)
    box off
    
    %Sample entropy plot w/discontinuities
    SE_tile = tiledlayout(fig,1,length(days_OG));
    SE_tile.Layout.TileSpan = [height_R2SE,3];
    SE_tile.Layout.Tile = (height_fullTD + height_zoomTD + height_timeline + 2*height_R2SE)*4 + 1;
    for i = 1:length(start_index)-1
        nexttile(SE_tile,[1,start_index(i+1)-start_index(i)]);
        hold on
        scatter(days(start_index(i)+1:start_index(i+1)),SE(start_index(i)+1:start_index(i+1)),sz,'filled','MarkerFaceColor',c_SE,'MarkerFaceAlpha',0.3)
        EMA_plot(days(start_index(i)+1:start_index(i+1)),SE(start_index(i)+1:start_index(i+1)),c_SE,ema_skip)
        xlim([min(days(start_index(i)+1:start_index(i+1)),[],'all'),max(days(start_index(i)+1:start_index(i+1)),[],'all')])
        ylim(ylim_SE)
        if i == 1
            set(gca,'FontSize',font_size,'TickLength',[tick_size,0]);
            ylabel('Sample Entropy')
        else
            set(gca,'YTick',[],'FontSize',font_size,'TickLength',[tick_size,0]);
        end
    end
    
    %Sample entropy violin plot
    nexttile(fig,[height_R2SE,1]);
    group = [repelem({'Pre-DBS'},sum(days<0)),repelem({'Post-DBS'},length(non_responder_idx)+length(responder_idx))];
    data = [SE(days<0)';SE([responder_idx,non_responder_idx])'];
    if ~isempty(non_responder_idx)
        violinplot(data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');       
        violinplot(data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_nonresponder,'HalfViolin','right','QuartileStyle','shadow');       
    else
        violinplot(data(contains(group,'Pre')),group(contains(group,'Pre')),'ViolinColor',c_nonresponder,'HalfViolin','left','QuartileStyle','shadow');
        violinplot(data(contains(group,'Post')),group(contains(group,'Post')),'ViolinColor',c_responder,'HalfViolin','right','QuartileStyle','shadow');
    end
    set(gca,'XTick',[0.8,1.2],'XTickLabels',{'Pre-DBS','Chronic State'},'TickLength',[tick_size,0],'FontSize',font_size)
    xlim([0.5,1.5])
    ylim(ylim_SE)
    box off
    fig.Padding = 'none';
end

function EMA_plot(days,stat,color,ema_skip)
    skip_idx = max([ema_skip,find(~isnan(stat),1,'first')]); %Skip 1st data point or initial NaN points when identifying start of EMA
    try
        plot(days(skip_idx:end),movavg(fillmissing(stat(skip_idx:end)','pchip','EndValues','none'),"exponential",5),'Color',color,'LineWidth',2);
    end
end