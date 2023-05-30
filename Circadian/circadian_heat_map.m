
load([loaddir,'spectro_days.mat'])
load([loaddir,'spectro_LFP_norm.mat'])

x_tick_scale=10; %adjust distance between x ticks here
color_height=1; %can adjust the height ratio of colorbar to spectrogram here
spectro_height=7;
fontsize = 10;
total_height=color_height+spectro_height;
%fig = figure('Renderer', 'painters', 'PaperUnits','centimeters','PaperPosition',[0,0,8.7,8.85]);

fig = tiledlayout(total_height*5,319);
set(gcf,'Renderer','painters');%,'PaperUnits','centimeters','PaperPosition',[0,0,8.7,8.85])
red={[15:196];[0:35];[0:19,];[];[];[];[0:54]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
blue={[];[176:364];[95:273];[];[];[];[55:100]}; %HEALTHY days of green from Gabriel

for j=[7,1:4] %starts with 001->008

    nan_locs=find(all(isnan(comb_LFP_norm_matrix{j,1}),1));
    LFP_norm_plot_no_nan=comb_LFP_norm_matrix{j,1}(:,setdiff(1:end,nan_locs));

    start_index=find(diff(comb_days{j,1})>1);
    try
        start_index=[1,start_index+1];
    catch
        start_index=1;
    end
    subplot_number=length(start_index);
    
    %generating colormap
    [~,red_idx]=intersect(comb_days{j,1},red{j});
    [~,blue_idx]=intersect(comb_days{j,1},blue{j});
    [~,purple_idx]=intersect(comb_days{j,1},min(comb_days{j,1}):-1);
    [~,yellow_idx]=intersect(comb_days{j,1},0:max(comb_days{j,1}));

    c_map=zeros(length(comb_days{j,1}),3);
   %c_map(purple_idx,:)=repmat([0.6,0,0.8],[length(purple_idx),1]);
    c_map([yellow_idx;purple_idx],:)=repmat([0.95,0.95,0],[length(yellow_idx)+length(purple_idx),1]);
    c_map(red_idx,:)=repmat([0.8,0,0],[length(red_idx),1]);
    c_map(blue_idx,:)=repmat([0,0,0.8],[length(blue_idx),1]);
    
    %colorbar plot
    for i=1:subplot_number
        if i==subplot_number %last plot
            h=nexttile([color_height,length(comb_days{j,1})-start_index(i)]);
            imagesc([comb_days{j,1}(start_index(i)),comb_days{j,1}(end)],[],1:length(comb_days{j,1})-start_index(i));
            colormap(h,c_map(start_index(i):end,:));
            xlim([comb_days{j,1}(start_index(i))-.5,comb_days{j,1}(end)+.5])
        else
            h=nexttile([color_height,start_index(i+1)-start_index(i)]);
            imagesc([comb_days{j,1}(start_index(i)),comb_days{j,1}(start_index(i+1)-1)],[],1:start_index(i+1)-start_index(i));
            colormap(h,c_map(start_index(i):start_index(i+1)-1,:))
            xlim([comb_days{j,1}(start_index(i))-.5,comb_days{j,1}(start_index(i+1)-1)+.5])
        end               
        set(gca,'Visible','off','Color','none')
    end

    %blank plot
    if  length(comb_days{j,1}) ~= fig.GridSize(2)
        nexttile([color_height,fig.GridSize(2)-length(comb_days{j,1})])
        set(gca,'XTick',[],'YTick',[],'color','none','Visible','off');
    end
    
    %spectrogram
    for i=1:subplot_number
        if i==subplot_number %last plot
            ax2{j}=nexttile([spectro_height,length(comb_days{j,1})-start_index(i)]);
            imagesc([comb_days{j,1}(start_index(i)),comb_days{j,1}(end)],[],LFP_norm_plot_no_nan(:,start_index(i):end));
            xticks = x_tick_scale*ceil(comb_days{j,1}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,1}(end)/x_tick_scale);
        else
            ax2{j}=nexttile([spectro_height,start_index(i+1)-start_index(i)]);
            imagesc([comb_days{j,1}(start_index(i)),comb_days{j,1}(start_index(i+1)-1)],[],LFP_norm_plot_no_nan(:,start_index(i):start_index(i+1)-1));
            xticks = x_tick_scale*ceil(comb_days{j,1}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,1}(start_index(i+1)-1)/x_tick_scale);
        end
    
        xline(0,'--y','LineWidth',2,'Alpha',1)
    
        colormap(ax2{j},jet)
        clim([-1,10])
        
        if i==1 %plot y axis on first plot
            yticks = [0.5,24:24:144];
            yticklabels = {'0:00','4:00','8:00','12:00','16:00','20:00','24:00'};
            set(gca,'YTick',yticks,'YTickLabels',yticklabels,'FontSize',fontsize);
            ylabel('Time of Day')
        else
            set(gca,'YTick',[]);
        end
        
        set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',fontsize)
        xtickangle(45)
    
    end

    %blank plot
    if length(comb_days{j,1}) ~= fig.GridSize(2)
        nexttile([spectro_height,fig.GridSize(2)-length(comb_days{j,1})])
        set(gca,'XTick',[],'YTick',[],'color','none','Visible','off','FontSize',fontsize);
    end
    
end
xlabel(fig,'Days Since DBS On','FontSize',fontsize);
set(gcf,'Position',[0,0,1300,1700])
%set(gcf,'PaperUnits','centimeters','PaperPosition',[0,0,13,17])

saveas(gcf,[savedir,'spectrograms.png'])
saveas(gcf,[savedir,'spectrograms.svg'])