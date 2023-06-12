output_file_name = '/Users/sameerrajesh/Desktop/006.gif';
pre_DBS_FPS = 1; %frames per second
post_DBS_FPS = 10; %frames per second

x_tick_scale = 50;
pos = [0,0,1600,900]; % please keep this in a 16:9 aspect ratio
ylims = []; % 0-1 for R^2, 0-1.2 for amplitude; otherwise leave blank
tick_height = [0.005,0.005]; % x and y tick height
y_name = 'Sample Entropy'; %y axis label
stat = comb_entropy; %change metric variable here
EMA_window = 10; %number of days for exponential moving average (EMA)
sz = 25; %dot sizes
EMA_sz = 3; %line width for EMA
patch_alpha = [.85,0.81,.63,.5]; %transparency for background colors

%colors
c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;

%patch colors
p_red = [236, 34, 39]/256;
p_blue = [59,84,165]/256;
p_orange = [123,51,147]/256;
p_yellow = [254,215,0]/256;

c_dots = [168,170,173]/256;
c_EMA = [0,0,0];

%color indices
red={[];[30:69];[0:8];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
blue={[48:100];[];[176:665];[95:273];[]}; %HEALTHY days of blue from Gabriel
orange={[];[0:29,70:296];[];[];[0:396]};

for k=1 %hemisphere
    framecount =1;
    for j=5 %[3,1,4,5,2]
        
        fig=figure;
        set(gcf,'Position',pos,'Color','w')
        
        %Complete all calculations before iterating for speed
        c1 = stat{j,k}(1,:,1);
        xticks = x_tick_scale*ceil(min(comb_days{j,1})):x_tick_scale:x_tick_scale*floor(max(comb_days{j,k}));
        start_index=find(diff(comb_days{j,k})>1);
        try
            start_index=[1,start_index+1,length(comb_days{j,k})+1];
        catch
            start_index=[1,length(comb_days{j,k})+1];
        end
        
        EMA=nan(length(comb_days{j,k}));
        for m=1:length(start_index)-1
            try
                EMA(start_index(m)+1:start_index(m+1)-1)=movavg(c1(start_index(m)+1:start_index(m+1)-1)',"exponential",5);
            end
        end
        
        q=fillData(comb_LFP_raw_matrix{j,k+1},comb_days{j,k});
        q=decibelize(q);
        
        for a=1:size(q,2)
         
            subplot(2,1,1)
            if ~isempty(intersect(comb_days{j,k}(a),-999:1))
                polarplot(0:2*pi/144:2*pi*143/144,q(:,a),'Color',c_yellow,'LineWidth',2)
            elseif ~isempty(intersect(comb_days{j,k}(a),orange{j}))
                polarplot(0:2*pi/144:2*pi*143/144,q(:,a),'Color',c_orange,'LineWidth',2)
            elseif ~isempty(intersect(comb_days{j,k}(a),red{j}))
                polarplot(0:2*pi/144:2*pi*143/144,q(:,a),'Color',c_red,'LineWidth',2)
            elseif ~isempty(intersect(comb_days{j,k}(a),blue{j}))
                polarplot(0:2*pi/144:2*pi*143/144,q(:,a),'Color',c_blue,'LineWidth',2)
            else
                polarplot(0:2*pi/144:2*pi*143/144,q(:,a),'Color',c_dots,'LineWidth',2)
            end
            
            pax=gca;
            set(pax,'ThetaDir','clockwise','ThetaZeroLocation','top','FontSize',25,'RTickLabels',[])
            thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
            pax.LineWidth=1.5;
            rlim([min(min(q)),6])

            h=subplot(2,1,2);
            h.Position([2,4])=[0.1,0.25];
            cla
            pax.Position([2,4])=[0.43,0.5];
            hold on
            
            %background patches
            try
                patch([red{j}(1),red{j}(1),red{j}(end),red{j}(end)],[0,10,10,0],p_red,'FaceAlpha',patch_alpha(1),'LineStyle','none')
            end
            try
                patch([blue{j}(1),blue{j}(1),blue{j}(end)+1,blue{j}(end)+1],[0,10,10,0],p_blue,'FaceAlpha',patch_alpha(2),'LineStyle','none')
            end
            try %002 has multiple purple regions
                if ~isempty(find(diff(orange{j})>1,1))
                    patch([orange{j}(1),orange{j}(1),orange{j}(diff(orange{j})>1)+1,orange{j}(diff(orange{j})>1)+1],[0,10,10,0],p_orange,'FaceAlpha',patch_alpha(3),'LineStyle','none')
                    patch([orange{j}(find(diff(orange{j})>1)+1)-1,orange{j}(find(diff(orange{j})>1)+1)-1,orange{j}(end)+1,orange{j}(end)+1],[0,10,10,0],p_orange,'FaceAlpha',patch_alpha(3),'LineStyle','none')
                else    
                    patch([orange{j}(1),orange{j}(1),orange{j}(end)+1,orange{j}(end)+1],[0,10,10,0],p_orange,'FaceAlpha',patch_alpha(3),'LineStyle','none')
                end
            end
            try
                patch([min(comb_days{j,k})-1,min(comb_days{j,k})-1,0,0],[0,10,10,0],p_yellow,'FaceAlpha',patch_alpha(4),'LineStyle','none')
            end
        
            %scatter plot of values
            xlim([min(comb_days{j,k}-1),max(comb_days{j,k}+1)])            
            scatter(comb_days{j,k}(1:a),c1(1:a),sz,c_dots,'filled')
            set(gca,'XTick',xticks,'XTickLabels', arrayfun(@num2str, xticks, 'UniformOutput', 0),'FontSize',20,'TickLength',tick_height)

            xlabel('Days Since DBS On',FontSize=25)

            ylabel(y_name,FontSize=25)
            if ~isempty(ylims)
                ylim(ylims)
            else
                ylim([0,max(c1(2:end))])
            end
            
            %EMA plot       
            plot(comb_days{j,k}(1:a),EMA(1:a),'Color',c_EMA,'LineWidth',EMA_sz);            
            hold off
            
            %Save gif
            F=[];
            F=getframe(fig);
            F2=frame2im(F);
            [A,map] = rgb2ind(F2,256);
            if a == 1 %set to repeat first frame
                for m = 1:10
                    imwrite(A,map,output_file_name,"gif","LoopCount",Inf,"DelayTime",1/pre_DBS_FPS/post_DBS_FPS);
                    framecount = framecount+1;
                end
            elseif framecount<=40%%comb_days{j,k}(a) < 0 | ismember(comb_days{j,k}(a),red{j})%pre-DBS
                for m = 1:10
                    imwrite(A,map,output_file_name,"gif","WriteMode","append","DelayTime",1/pre_DBS_FPS/post_DBS_FPS);
                    framecount = framecount+1;
                end
            elseif framecount >40 & framecount<=120
                for m = 1:5
                    imwrite(A,map,output_file_name,"gif","WriteMode","append","DelayTime",0.5/pre_DBS_FPS/post_DBS_FPS);
                    framecount = framecount+1;
                end
            
            else
                imwrite(A,map,output_file_name,"gif","WriteMode","append","DelayTime",1/post_DBS_FPS);
                framecount = framecount+1;
            end
            
        end
    end
end