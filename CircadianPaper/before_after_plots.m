function before_after_plots(percept_data,hemisphere)
    %% Detailed inputs
    
    c_responder = [0,0,255]/255; % Color of chronic responder zone
    c_nonresponder = [255,215,0]/255; % Color of chronic non-responder zone
    c_linAR = [213,62,79]/255; % Color of linear AR line in ROC
    c_nonlinAR = [0,200,0]/255; % Color of non-linear AR line in ROC
    c_cosinor = [252,141,89]/255; % Color of cosinor line in ROC
    c_SE = [0,0,64]/255; % Color of sample entropy line in ROC
    
    sz = 100; % Size of shapes in before-after plots
    face_alpha = 0.7; % Transparency of shapes in before-after plots
    line_alpha = 0.5; % Transparency of connecting lines in before-after plots
    
    % This group of variables adjusts spacing of before-after plot
    x_preDBS = 1.5; % X location of pre-DBS points in before-after plots
    x_postDBS = 2; % X location of post-DBS points in before-after plots
    x_delta = 3; % X location of delta points in before-after plots
    font_size_label = 8; % Font size of patient labels in before-after plot
    x_preDBS_label = 1; % X location of patient labels to left of pre-DBS
    x_postDBS_label = 2.1; % X location of patient labels to right of post-DBS (if not pre-DBS point for that patient)
    x_delta_label = 2.5; % X location of patient labels to left of delta
    x_lims = [1,3.2]; % X limits for before-after plot (make sure it includes all data points + labels)
    threshold_width = 0.2; % Width of dotted threshold line past the boundary of the dots
    
    ylim_SE = [0,0.04]; % Y axis limits for sample entropy
    ylim_delta_SE = [-0.03,0.03]; % Y axis limits for delta sample entropy
    ylim_R2 = [0,85]; % Y axis limits for cosinor/AR R^2
    ylim_delta_R2 = [-70,70]; % Y axis limits for cosinor/AR delta R^2
    
    fig_position = [0,0,30,30]; % Make this a square
    
    font_size_beforeafter = 12; % Axis font size for before-after plot
    font_size_ROC = 12; % Axis font size for ROC
    font_size_legend = 12; % Font size of legend in ROC plots
    
    %% Plotting
    
    figure('Units','centimeters','Position',fig_position);
    fig = tiledlayout(2,4);
    
    model_name = {'cosinor','linearAR','nonlinearAR','entropy'};
    actual_model_name = {'Cosinor','Linear AR','Non-linear AR','Sample Entropy'};
    
    for m = 1:4
        nexttile(fig,[1,1])
        
        %Temporary variables per iteration
        data = percept_data.kfold.(model_name{m}){hemisphere};
        chronic = nanmax(data.Responder,data.Non_Responder);
        
        hold on
        yyaxis left
        plot(repmat([x_preDBS,x_postDBS,NaN],1,size(data,1)),reshape([data.Pre_DBS';chronic';nan(1,size(data,1))],[1,size(data,1)*3]),'-k','Color',[0,0,0,line_alpha],'LineWidth',1);

        scatter(repelem([x_preDBS,x_postDBS],size(data,1)),[data.Pre_DBS;data.Non_Responder],sz,'filled','MarkerEdgeColor',c_nonresponder,'MarkerFaceColor',c_nonresponder,'MarkerFaceAlpha',face_alpha);
        scatter(repelem(x_postDBS,size(data,1)),data.Responder,sz,'^','filled','MarkerEdgeColor',c_responder,'MarkerFaceColor',c_responder,'MarkerFaceAlpha',face_alpha);
    
        text(repelem(x_preDBS_label,size(data,1)),data.Pre_DBS,data.Subject,'FontSize',font_size_label)
        text(repelem(x_postDBS_label,sum(isnan(data.Pre_DBS))),chronic(isnan(data.Pre_DBS)),data.Subject(isnan(data.Pre_DBS)),'FontSize',font_size_label)
        
        % Plot threshold line if clear demarcation exists
        if max([data.Pre_DBS;data.Non_Responder]) < min(data.Responder)
            threshold = median([max([data.Pre_DBS;data.Non_Responder]),min(data.Responder)]);
            plot([x_preDBS-threshold_width,x_postDBS+threshold_width],[threshold,threshold],'--k')
        elseif min([data.Pre_DBS;data.Non_Responder]) > max(data.Responder)
            threshold = median([min([data.Pre_DBS;data.Non_Responder]),max(data.Responder)]);
            plot([x_preDBS-threshold_width,x_postDBS+threshold_width],[threshold,threshold],'--k')
        end
    
        if m == 4
            ylabel('Sample Entropy')
            ylim(ylim_SE)
        else
            ylabel('R^2 (%)')
            ylim(ylim_R2/100)
            set(gca,'YTickLabel',arrayfun(@num2str, 100*get(gca,'YTick'), 'UniformOutput', 0))
        end
    
        yyaxis right
        delta = sum([data.Pre_DBS,-chronic],2);
        responder_idx = find(~isnan(data.Responder));
        nonresponder_idx = find(~isnan(data.Non_Responder));
    
        scatter(repelem(x_delta,length(nonresponder_idx)),delta(nonresponder_idx),sz,'filled','MarkerEdgeColor',c_nonresponder,'MarkerFaceColor',c_nonresponder,'MarkerFaceAlpha',face_alpha);
        scatter(repelem(x_delta,length(responder_idx)),delta(responder_idx),sz,'^','filled','MarkerEdgeColor',c_responder,'MarkerFaceColor',c_responder,'MarkerFaceAlpha',face_alpha);
    
        text(repelem(x_delta_label,size(data,1)),delta,data.Subject,'FontSize',font_size_label);
    
        if max(delta(responder_idx)) < min(delta(nonresponder_idx))
            threshold = median([max(delta(responder_idx)),min(delta(nonresponder_idx))]);
            plot([x_delta-threshold_width,x_delta+threshold_width],[threshold,threshold],'--k')
        elseif min(delta(responder_idx)) > max(delta(nonresponder_idx))
            threshold = median([min(delta(responder_idx)),max(delta(nonresponder_idx))]);
            plot([x_delta-threshold_width,x_delta+threshold_width],[threshold,threshold],'--k')
        end
        
        if m == 4
            ylim(ylim_delta_SE)
            ylabel('\Delta Sample Entropy','Rotation',270)
        else
            ylim(ylim_delta_R2/100)
            ylabel('\Delta R^2 (%)','Rotation',270)
            set(gca,'YTickLabel',arrayfun(@num2str, 100*get(gca,'YTick'), 'UniformOutput', 0))
        end
    
        hold off
        title(actual_model_name{m})
        xlim(x_lims)
        xticks([x_preDBS,2,3])
        xticklabels({'Pre-DBS','Chronic Status','\Delta'})
        ax = gca;
        ax.YAxis(1).Color = 'k';
        ax.YAxis(2).Color = 'k';
        ax.FontSize = font_size_beforeafter;
        ax.TickLength(1) = 0;
        box on
    end
    
    nexttile(fig,[1,2])
    hold on
    plot([0,1],[0,1],'--k')
    for m = 1:4
        ROC = percept_data.ROC.(model_name{m}){1,hemisphere+1};
        [FPR,TPR] = perfcurve(ROC.True,ROC.Prediction,1);
        plot(FPR,TPR,'LineWidth',2)
    end
    hold off
    
    set(gca,'XTick',0:0.1:1,'YTick',0:0.1:1,'FontSize',font_size_ROC)
    legend([{''},strcat(actual_model_name,{' R^2',' R^2',' R^2',''})],'Location','southeast','FontSize',font_size_legend)
    legend boxoff
    xlim([0,1])
    xlabel('False Positive Rate')
    ylim([0,1])
    ylabel('True Positive Rate')
    box on
    axis square
    colororder(gca,[0,0,0;c_cosinor;c_linAR;c_nonlinAR;c_SE])
    
    nexttile(fig,[1,2])
    hold on
    
    plot([0,1],[0,1],'--k')
    for m = 1:4
        ROC = percept_data.ROC.(model_name{m}){2,hemisphere+1};
        [FPR,TPR] = perfcurve(ROC.True,ROC.Prediction,1);
        plot(FPR,TPR,'LineWidth',2)
    end
    hold off
    
    set(gca,'XTick',0:0.1:1,'YTick',0:0.1:1,'FontSize',font_size_ROC)
    legend([{''},strcat(actual_model_name,{' \DeltaR^2',' \DeltaR^2',' \DeltaR^2',' \Delta'})],'Location','southeast','FontSize',font_size_legend)
    legend boxoff
    xlim([0,1])
    xlabel('False Positive Rate')
    ylim([0,1])
    ylabel('True Positive Rate')
    box on
    axis square
    colororder(gca,[0,0,0;c_cosinor;c_linAR;c_nonlinAR;c_SE])

end