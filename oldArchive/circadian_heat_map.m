

%% User Inputs
load([loaddir loadfile]);
%% Formatting
% load data

x_tick_scale=20; %adjust distance between x ticks here
fontsize = 8; %set font size
num_patients=5; %set equal to number of patients to be plotted
color_height=0.003; %colorbar height
spectro_height=0.115; %spectrogram height
horiz_space_bw_plots=0.005; %set horizontal gap between bars/spectrograms
width_scale=0.8; %set relative width of all the bars/spectrograms
max_day_width=319; %enter the max number of days out of the patients to be plotted

%colors
c_red = [255,0,0]/255;
c_blue = [0,0,255]/255;
c_purple = [127,63,152]/255;
c_yellow = [255,215,0]/255;
c_white = [255,255,255]/255;

red={[30:68];[0:8];[0:4];[];[];[];[]}; %HYPOMANIA+DISINHIBITION days of red
blue={[];[176:489];[95:273];[];[];[];[48:100]}; %HEALTHY days of blue
purple={[197:296];[];[];[];[];[90:396];[]};

if target==1
    red={[];[30:68];[0:8];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
    blue={[48:100];[];[176:665];[95:290];[]}; %HEALTHY days of blue from Gabriel
    purple={[0:47];[0:29,70:296];[9:175];[5:94];[0:396]};
else
    red={[];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
    blue={[48:100];[95:290];[]}; %HEALTHY days of blue from Gabriel
    purple={[0:47];[5:94];[0:396]};
end

iteration_count=1;
%% Plotting
figure('Units','inches','Position',[0 0 5.9 7.3]);
% GPi plotting exceptions
if target==1
    pt_range = [1:5];
else
    pt_range = [1,2];
end

for j=pt_range %starts with 001->008
    
    LFP_norm_plot_no_nan=comb_LFP_norm_matrix{j,hem+1};

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
    [~,purple_idx]=intersect(comb_days{j,hem},purple{j});

    c_map=ones(length(comb_days{j,hem}),3);
    c_map(yellow_idx,:)=repmat(c_yellow,[length(yellow_idx),1]);
    
    if j==1 || j==3 || j==4% || j==2
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
    for i = 1:subplot_number
    ax1{i}.Position(2)=ax1{i}.Position(2)+0.035;
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
        clim([-1,7])
        
        if i==1 %plot y axis on first plot
            %yticks = [0.5,24:24:144];
            %yticklabels = {'0:00','4:00','8:00','12:00','16:00','20:00','24:00'};
            yticks = [0.5,36:36:144];
            yticklabels = {'0:00','','12:00','','24:00'};            
            set(gca,'YTick',yticks,'YTickLabels',yticklabels,'TickLength',[0.01,0.01],'FontSize',fontsize);
            ylabel(strcat('P',comb_LFP_norm_matrix(j,1)))
        else
            set(gca,'YTick',[]);
        end
        
        set(gca,'LineWidth',0.1,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',fontsize)
        xtickangle(45)
        ax2{i}.Position(4)=spectro_height;
    end
    
    iteration_count=iteration_count+1;
    
end

% set(gcf,'Position',[0,0,750,1301]);
% set(gcf,'Units','inches','Renderer','painters','Position',[0 0 4.3 7.3])
exportgraphics(gcf,savedir,'ContentType','vector');
% annotation('textbox',[0,0.05,1,0],'String','Days Since DBS Activation','FontSize',fontsize,'HorizontalAlignment','center','LineStyle','none')
% set(gcf,'PaperUnits','centimeters','PaperPosition',[0,0,13,17])

