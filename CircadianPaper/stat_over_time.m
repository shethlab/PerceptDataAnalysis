x_tick_scale = 50;
pos = [0,0,1800,1200];
ylims = []; % 0-1 for R^2, 0-1.2 for amplitude; otherwise leave blank
tick_height = [0.005,0.005]; % x and y tick height
y_name = 'Sample Entropy'; %y axis label
stat = comb_amp; %change metric variable here
EMA_window = 10; %number of days for exponential moving average (EMA)
sz = 20; %dot sizes
EMA_sz = 3; %line width for EMA
patch_alpha = 0.3; %transparency for background colors
font_size = 12;

%colors
c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_purple = [127,63,152]/255;
c_yellow = [255,215,0]/255;

c_dots = [0.5,0.5,0.5];
c_EMA = [0,0,0];

%color indices
red={[];[30:69];[0:8];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red 
blue={[48:100];[];[176:665];[95:273];[]}; %HEALTHY days of blue 
purple={[];[0:29,70:296];[];[];[0:396]};
ema = {};
for k=2 %hemisphere
    fig=tiledlayout(5,1);
    for j=[3,1,4,5,2]  
        c1 = stat{j,k}(1,:,1);
    
        h{j}=nexttile;
        hold on
        
        %background patches
        try
            patch([red{j}(1),red{j}(1),red{j}(end),red{j}(end)],[0,10,10,0],c_red,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
        try
            patch([blue{j}(1),blue{j}(1),blue{j}(end)+1,blue{j}(end)+1],[0,10,10,0],c_blue,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
        try %002 has multiple purple regions
            if ~isempty(find(diff(purple{j})>1))
                patch([purple{j}(1),purple{j}(1),purple{j}(find(diff(purple{j})>1))+1,purple{j}(find(diff(purple{j})>1))+1],[0,10,10,0],c_purple,'FaceAlpha',patch_alpha,'LineStyle','none')
                patch([purple{j}(find(diff(purple{j})>1)+1)-1,purple{j}(find(diff(purple{j})>1)+1)-1,purple{j}(end)+1,purple{j}(end)+1],[0,10,10,0],c_purple,'FaceAlpha',patch_alpha,'LineStyle','none')
            else    
                patch([purple{j}(1),purple{j}(1),purple{j}(end)+1,purple{j}(end)+1],[0,10,10,0],c_purple,'FaceAlpha',patch_alpha,'LineStyle','none')
            end
        end
        try
            patch([min(comb_days{j,k})-1,min(comb_days{j,k})-1,0,0],[0,10,10,0],c_yellow,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
        
        %scatter plot of values
        xticks = x_tick_scale*ceil(min(comb_days{j,1})):x_tick_scale:x_tick_scale*floor(max(comb_days{j,k}));
        xlim([min(comb_days{j,k}-1),max(comb_days{j,k}+1)])
        if j==2
            scatter(comb_days{j,k},c1,sz,[0.5,0.5,0.5],'filled')
            xlabel('Days Since DBS On',FontSize=font_size)
            set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',font_size,'TickLength',tick_height)
        elseif j==5
            scatter(comb_days{j,k}(2:end),c1(2:end),sz,[0.5,0.5,0.5],'filled')
            set(gca,'XTick',[],'XTickLabels',[],'TickLength',tick_height,'FontSize',font_size)
        else
            scatter(comb_days{j,k},c1,sz,[0.5,0.5,0.5],'filled')
            set(gca,'XTick',[],'XTickLabels',[],'TickLength',tick_height,'FontSize',font_size)
        end
        %title(comb_LFP_norm_matrix{j,1},'FontSize',20)

        ylabel(y_name)
        if ~isempty(ylims)
            ylim(ylims)
        else
            ylim([0,max(c1(2:end))])
        end
        
        %EMA plot       
        start_index=find(diff(comb_days{j,k})>1);
        try
            start_index=[1,start_index+1,length(comb_days{j,k})+1];
        catch
            start_index=[1,length(comb_days{j,k})+1];
        end
        ema{j,k} = [];
        for m=1:length(start_index)-1
            try
                plot(comb_days{j,k}(start_index(m)+1:start_index(m+1)-1),movavg(fillmissing(c1(start_index(m)+1:start_index(m+1)-1),'pchip')',"exponential",5),'Color',c_EMA,'LineWidth',EMA_sz);
                ema{j,k}(start_index(m)+1:start_index(m+1)-1) = movavg(fillmissing(c1(start_index(m)+1:start_index(m+1)-1),'pchip')',"exponential",5);
            end
        end
    end
end
linkaxes([h{:}],'x')
fig.Padding='Compact';
set(gcf,'Position',pos)