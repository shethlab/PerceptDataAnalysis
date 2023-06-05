x_tick_scale = 20;
ylims = [0,0.06]; % 0-0.06 for entropy, 0-1 for R^2, 0-1.2 for amplitude
y_name = 'Sample Entropy'; %y axis label
stat = comb_entropy; %change metric variable here
EMA_window = 10; %number of days for exponential moving average (EMA)
sz = 20; %dot sizes
EMA_sz = 3; %line width for EMA
patch_alpha = 0.3; %transparency for background colors

%colors
c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;

c_dots = [0.5,0.5,0.5];
c_EMA = [0,0,0];

%color indices
red={[];[30:69];[0:8];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
blue={[48:100];[];[176:665];[95:273];[]}; %HEALTHY days of blue from Gabriel
orange={[];[0:29,70:296];[];[];[0:396]};

for k=1 %hemisphere
    fig=tiledlayout(5,1);
    for j=1:5  
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
            if ~isempty(find(diff(orange{j})>1))
                patch([orange{j}(1),orange{j}(1),orange{j}(find(diff(orange{j})>1))+1,orange{j}(find(diff(orange{j})>1))+1],[0,10,10,0],c_orange,'FaceAlpha',patch_alpha,'LineStyle','none')
                patch([orange{j}(find(diff(orange{j})>1)+1)-1,orange{j}(find(diff(orange{j})>1)+1)-1,orange{j}(end)+1,orange{j}(end)+1],[0,10,10,0],c_orange,'FaceAlpha',patch_alpha,'LineStyle','none')
            else    
                patch([orange{j}(1),orange{j}(1),orange{j}(end)+1,orange{j}(end)+1],[0,10,10,0],c_orange,'FaceAlpha',patch_alpha,'LineStyle','none')
            end
        end
        try
            patch([min(comb_days{j,k})-1,min(comb_days{j,k})-1,0,0],[0,10,10,0],c_yellow,'FaceAlpha',patch_alpha,'LineStyle','none')
        end
        
        %scatter plot of values
        scatter(comb_days{j,k},c1,sz,[0.5,0.5,0.5],'filled')
        title(comb_LFP_norm_matrix{j,1},'FontSize',20)
        if j==5
            xlabel('Days Since DBS On')
        end
        ylabel('Sample Entropy')
        xticks = x_tick_scale*ceil(min(comb_days{j,1})):x_tick_scale:x_tick_scale*floor(max(comb_days{j,k}));
        set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0))
        xlim([min(comb_days{j,k}-1),max(comb_days{j,k}+1)])
        ylim(ylims)
        
        %EMA plot       
        start_index=find(diff(comb_days{j,k})>1);
        try
            start_index=[1,start_index+1,length(comb_days{j,k})+1];
        catch
            start_index=[1,length(comb_days{j,k})+1];
        end

        for m=1:length(start_index)-1
            try
                plot(comb_days{j,k}(start_index(m)+1:start_index(m+1)-1),movavg(c1(start_index(m)+1:start_index(m+1)-1)',"exponential",5),'Color',c_EMA,'LineWidth',EMA_sz);
            end
        end
    end
end
linkaxes([h{:}],'x')
fig.Padding='Tight';