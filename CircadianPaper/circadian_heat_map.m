%% Load Data
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
load([loaddir,'VCVS_all.mat'])

x_tick_scale=20; %adjust distance between x ticks here
fontsize = 12; %set font size
num_patients=5; %set equal to number of patients to be plotted
color_height=0.01; %colorbar height
spectro_height=0.08; %spectrogram height
horiz_space_bw_plots=0.003; %set horizontal gap between bars/spectrograms
width_scale=0.8; %set relative width of all the bars/spectrograms
max_day_width=319; %enter the max number of days out of the patients to be plotted
hem = 1; %left hemisphere = 1, right = 2

%colors
c_red = [204,0,0]/255;
c_blue = [0,0,204]/255;
c_purple = [229,100,25]/255;
c_yellow = [255,215,0]/255;
c_white = [255,255,255]/255;

red={[30:69];[0:8];[0:4];[];[];[];[]}; %HYPOMANIA+DISINHIBITION days of red
blue={[];[176:489];[95:273];[];[];[];[48:100]}; %HEALTHY days of blue
purple={[197:296];[];[];[];[];[90:396];[]};
iteration_count=1;

% figure('Units','inches','Renderer','painters','Position',[0 0 5.5 5.5])
for j=[7,1:4] %starts with 001->008
    
    LFP_norm_plot_no_nan=comb_LFP_norm_matrix{j,2};

    start_index=find(diff(comb_days{j,hem})>1);
    try
        start_index=[1,start_index+1];
    catch
        start_index=1;
    end
    subplot_number=length(start_index);
    
    %generating colormap
    [~,red_idx]=intersect(comb_days{j,hem},red{j});
    [~,blue_idx]=intersect(comb_days{j,hem},blue{j});
    [~,yellow_idx]=intersect(comb_days{j,hem},min(comb_days{j,hem}):-1);
    [~,purple_idx]=intersect(comb_days{j,hem},0:max(comb_days{j,hem}));

    c_map=zeros(length(comb_days{j,hem}),3);
    c_map(yellow_idx,:)=repmat(c_yellow,[length(yellow_idx),1]);
    if j==2 | j==3
        c_map(purple_idx,:)=repmat(c_white,[length(purple_idx),1]);
    else
    c_map(purple_idx,:)=repmat(c_purple,[length(purple_idx),1]);
    end
    c_map(red_idx,:)=repmat(c_red,[length(red_idx),1]);
    c_map(blue_idx,:)=repmat(c_blue,[length(blue_idx),1]);
    
    %colorbar plot
    for i=1:subplot_number
        if i==1 & i~=subplot_number
            ax1{i}=subplot(2*num_patients,1,iteration_count*2-1);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(start_index(i+1)-1)],[],1:start_index(i+1)-start_index(i));
            colormap(ax1{i},c_map(start_index(i):start_index(i+1)-1,:))
            xlim([comb_days{j,hem}(start_index(i))-.5,comb_days{j,hem}(start_index(i+1)-1)+.5])
            ax1{i}.Position(3)=width_scale/max_day_width*ax1{i}.DataAspectRatio(1);
        elseif i==1 & i==subplot_number
            ax1{i}=subplot(2*num_patients,1,iteration_count*2-1);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(end)],[],1:length(comb_days{j,hem})-start_index(i));
            colormap(ax1{i},c_map(start_index(i):end,:));
            xlim([comb_days{j,hem}(start_index(i))-.5,comb_days{j,hem}(end)+.5])
            ax1{i}.Position(3)=width_scale/max_day_width*ax1{i}.DataAspectRatio(1);
        elseif i==subplot_number
            ax1{i}=axes('Position',[ax1{i-1}.Position(1)+ax1{i-1}.Position(3)+horiz_space_bw_plots,ax1{i-1}.Position(2),width_scale/max_day_width*(length(comb_days{j,hem})-start_index(i)),0.01]);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(end)],[],1:length(comb_days{j,hem})-start_index(i));
            colormap(ax1{i},c_map(start_index(i):end,:));
            xlim([comb_days{j,hem}(start_index(i))-.5,comb_days{j,hem}(end)+.5])
        else
            ax1{i}=axes('Position',[ax1{i-1}.Position(1)+ax1{i-1}.Position(3)+horiz_space_bw_plots,ax1{i-1}.Position(2),width_scale/max_day_width*(start_index(i+1)-start_index(i)-1),0.01]);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(start_index(i+1)-1)],[],1:start_index(i+1)-start_index(i));
            colormap(ax1{i},c_map(start_index(i):start_index(i+1)-1,:))
            xlim([comb_days{j,hem}(start_index(i))-.5,comb_days{j,hem}(start_index(i+1)-1)+.5])        
        end
        set(gca,'Visible','off','Color','none')
        ax1{i}.Position(4)=color_height;
    end
    
    %spectrogram
    for i=1:subplot_number
        if i==1 & i~=subplot_number
            ax2{i}=subplot(2*num_patients,1,iteration_count*2);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(start_index(i+1)-1)],[],LFP_norm_plot_no_nan(:,start_index(i):start_index(i+1)-1));
            xticks = x_tick_scale*ceil(comb_days{j,hem}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,hem}(start_index(i+1)-1)/x_tick_scale);
            ax2{i}.Position(3)=width_scale/(max_day_width/2)*ax2{i}.DataAspectRatio(1);
        elseif i==1 & i==subplot_number
            ax2{i}=subplot(2*num_patients,1,iteration_count*2);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(end)],[],LFP_norm_plot_no_nan(:,start_index(i):end));
            xticks = x_tick_scale*ceil(comb_days{j,hem}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,hem}(end)/x_tick_scale);
            ax2{i}.Position(3)=width_scale/(max_day_width/2)*ax2{i}.DataAspectRatio(1);
        elseif i==subplot_number %last plot
            ax2{i}=axes('Position',[ax2{i-1}.Position(1)+ax2{i-1}.Position(3)+horiz_space_bw_plots,ax2{i-1}.Position(2),width_scale/max_day_width*(length(comb_days{j,hem})-start_index(i)),0.08]);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(end)],[],LFP_norm_plot_no_nan(:,start_index(i):end));
            xticks = x_tick_scale*ceil(comb_days{j,hem}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,hem}(end)/x_tick_scale);
        else
            ax2{i}=axes('Position',[ax2{i-1}.Position(1)+ax2{i-1}.Position(3)+horiz_space_bw_plots,ax2{i-1}.Position(2),width_scale/max_day_width*(start_index(i+1)-start_index(i)-1),0.08]);
            imagesc([comb_days{j,hem}(start_index(i)),comb_days{j,hem}(start_index(i+1)-1)],[],LFP_norm_plot_no_nan(:,start_index(i):start_index(i+1)-1));
            xticks = x_tick_scale*ceil(comb_days{j,hem}(start_index(i))/x_tick_scale):x_tick_scale:x_tick_scale*floor(comb_days{j,hem}(start_index(i+1)-1)/x_tick_scale);
        end
    
        xline(0,'--y','LineWidth',2,'Alpha',1)
    
        colormap(ax2{i},jet)
        clim([-1,10])
        
        if i==1 %plot y axis on first plot
            %yticks = [0.5,24:24:144];
            %yticklabels = {'0:00','4:00','8:00','12:00','16:00','20:00','24:00'};
            yticks = [0.5,36:36:144];
            yticklabels = {'0:00','','12:00','','24:00'};            
            set(gca,'YTick',yticks,'YTickLabels',yticklabels,'FontSize',fontsize);
            ylabel(comb_LFP_raw_matrix(j,1))
        else
            set(gca,'YTick',[]);
        end
        
        set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',fontsize)
        ax2{i}.TickLength(1) = 1/ax2{i}.DataAspectRatio(1);
        xtickangle(45)
        ax2{i}.Position(4)=spectro_height;
    end

    iteration_count=iteration_count+1;
    
end

% set(gcf,'Position',[0,0,500,500])
annotation('textbox',[0,0.05,1,0],'String','Days Since DBS On','FontSize',fontsize,'HorizontalAlignment','center','LineStyle','none')
%set(gcf,'PaperUnits','centimeters','PaperPosition',[0,0,13,17])

%saveas(gcf,[savedir,'spectrograms.png'])
%saveas(gcf,[savedir,'spectrograms.svg'])