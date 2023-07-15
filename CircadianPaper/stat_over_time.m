function [] = stat_over_time(data,field,hemisphere,zone_index)

%% Detailed Adjustable Inputs

x_tick_scale = 50;
fig_position = [0,0,7.014,5];
ylims = []; % 0-1 for R^2, 0-1.2 for amplitude; otherwise leave blank
tick_height = [0.005,0.005]; % x and y tick height
EMA_window = 5; %number of days for exponential moving average (EMA)
sz = 3; %dot sizes
EMA_sz = 0.5; %line width for EMA
patch_alpha = 0.3; %transparency for background colors
font_size = 6;

%Color values (RGB 0-1)
c_mania = [255,0,0]/255;
c_responder = [0,0,255]/255;
c_nonresponder = [127,63,152]/255;
c_preDBS = [255,215,0]/255;
c_dots = [0.5,0.5,0.5];
c_EMA = [0,0,0];

%% Plotting

switch field
    case 'entropy'
        y_label = 'Sample Entropy';
    case 'amplitude'
        y_label = 'Amplitude';
    case 'acrophase'
        y_label = 'Acrophase';
    case 'cosinor_p'
        y_label = 'P-value';
    case 'cosinor_R2'
        y_label = 'R^2';
        ylims = [0,1];
    otherwise
        error('Inputted data field is invalid.')
end

fig=tiledlayout(size(data.days,1),1);

for j=1:size(data.days,1)  
    
    %Temporary variables per iteration
    days = data.days{j,hemisphere+1};
    stat = data.(field){j,hemisphere+1}(1,:,1);

    h{j}=nexttile;
    hold on
    
    %Background patches
    if ~isempty(zone_index.hypomania{j}) %Hypomania zone
        zone_idx = [0,find(diff(zone_index.hypomania{j})>1),length(zone_index.hypomania{j})];
        for i = 1:length(zone_idx)-1
            patch([zone_index.hypomania{j}(zone_idx(i)+1),zone_index.hypomania{j}(zone_idx(i)+1),zone_index.hypomania{j}(zone_idx(i+1))+1,zone_index.hypomania{j}(zone_idx(i+1))+1],[0,10,10,0],c_mania,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
    end

    if ~isempty(zone_index.responder{j}) %Responder zone
        zone_idx = [0,find(diff(zone_index.responder{j})>1),length(zone_index.responder{j})];
        for i = 1:length(zone_idx)-1
            patch([zone_index.responder{j}(zone_idx(i)+1),zone_index.responder{j}(zone_idx(i)+1),zone_index.responder{j}(zone_idx(i+1))+1,zone_index.responder{j}(zone_idx(i+1))+1],[0,10,10,0],c_responder,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
    end
    
    if ~isempty(zone_index.non_responder{j}) %Non-responder zone
        zone_idx = [0,find(diff(zone_index.non_responder{j})>1),length(zone_index.non_responder{j})];
        for i = 1:length(zone_idx)-1
            patch([zone_index.non_responder{j}(zone_idx(i)+1),zone_index.non_responder{j}(zone_idx(i)+1),zone_index.non_responder{j}(zone_idx(i+1))+1,zone_index.non_responder{j}(zone_idx(i+1))+1],[0,10,10,0],c_nonresponder,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
    end
    
    patch([min(days)-1,min(days)-1,0,0],[0,10,10,0],c_preDBS,'FaceAlpha',patch_alpha,'LineStyle','none') %Pre-DBS zone
    
    %Scatter plot of values
    scatter(days,stat,sz,c_dots,'filled')
    
    %X ticks, labels, and limits
    xticks = x_tick_scale*ceil(min(days)):x_tick_scale:x_tick_scale*floor(max(days));
    xlim([min(days-1),max(days+1)])
    if j == size(data.days,1) %Lowest plot
        xlabel('Days Since DBS Activation',FontSize=font_size)
        set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',font_size,'TickLength',tick_height)
    else
        set(gca,'XTick',[],'XTickLabels',[],'TickLength',tick_height,'FontSize',font_size)
    end
    
    %Y labels and limits
    ylabel(y_label)
    if ~isempty(ylims)
        ylim(ylims)
        yticks(ylims)
    else
        ylim(round([0,max(stat(2:end))],2,"decimals","TieBreaker","fromzero"))
    end
    
    %Find indices of discontiuous days of data       
    start_index=find(diff(days)>1);
    if ~isempty(start_index)
        start_index=[1;start_index+1;length(days)+1];
    else
        start_index=[1;length(days)+1];
    end
    
    %EMA plot
    for i=1:length(start_index)-1
        skip_idx=max([2,find(~isnan(stat(start_index(i):end)),1,'first')]); %Skip 1st data point or initial NaN points when identifying start of EMA
        ind=start_index(i)+skip_idx-1:start_index(i+1)-1;
        try
            plot(days(ind),movavg(fillmissing(stat(ind),'pchip','EndValues','none')',"exponential",EMA_window),'Color',c_EMA,'LineWidth',EMA_sz);
        end
    end
end

linkaxes([h{:}],'x')
linkaxes([h{:}],'y')
fig.Padding='Compact';

end