%% This function is used to visualize changes in various data metrics across
% all patients as described in Provenza, Reddy, and Allam et al. 2024. 
% Metrics include cosinor R2, linear autoregressive R2, non-linear 
% autoregressive R2, and sample entropy. This function requires two inputs:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is something.py, which creates the
%       appropriately-formatted data structure. This structure must contain
%       fields called "kfold," and "ROC."
%   3. hemisphere: the hemisphere of data to display. Set to 1 for left or
%       2 for right.
%
% This function outputs a figure in the format of Figure 5 from the main 
% manuscript. The top row contains plots of deltas (difference between
% pre-DBS and post-DBS) for each patient across the four metrics, and an
% AUC-ROC for a classifier combining all patients. The bottom row contains
% before-after plots compared pre-DBS and post-DBS in each patient across
% the four metrics, and an AUC-ROC for a classifier combining all patients.

function plot_deltas(percept_data,hemisphere)

%% Detailed inputs

c_responder = [0,0,255]/255; % Color of chronic responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS scatter plot
c_preDBS_outline = [128,128,128]/255; % Color of pre-DBS outline
c_nonresponder = [255,185,0]/255; % Color of chronic non-responder zone
c_nonlinAR = [178,223,128]/255; % Color of non-linear AR line in ROC
c_linAR = [51,160,44]/255; % Color of linear AR scatter plot/line
c_cosinor = [251,154,153]/255; % Color of cosinor scatter plot/line
c_SE = [106,61,154]/255; % Color of sample entropy scatter plot/line

sz = 100; % Size of shapes in before-after plots
face_alpha = 0.7; % Transparency of shapes in before-after plots
line_alpha = 0.5; % Transparency of connecting lines in before-after plots

% This group of variables adjusts spacing of before-after plot
x_preDBS = 1.5; % X location of pre-DBS points in before-after plots
x_postDBS = 2; % X location of post-DBS points in before-after plots
x_delta = 3; % X location of delta points in before-after plots
font_size_label = 8; % Font size of patient labels in before-after plot
x_preDBS_label = 1.25; % X location of patient labels to left of pre-DBS
x_postDBS_label = 2.1; % X location of patient labels to right of post-DBS (if not pre-DBS point for that patient)
x_delta_label = 2.8; % X location of patient labels to left of delta
x_lims_norm = [1.2,2.3]; % X limits for before-after top row plots
x_lims_delta = [2.5,3.5]; % X limits for before-after bottom row plots
threshold_width = 0.2; % Width of dotted threshold line past the boundary of the dots

ylim_SE = [0,0.04]; % Y axis limits for sample entropy
ylim_delta_SE = [-0.02,0.02]; % Y axis limits for delta sample entropy
ylim_R2 = [-5,80]; % Y axis limits for cosinor/AR R^2
ylim_delta_R2 = [-20,60]; % Y axis limits for cosinor/AR delta R^2

fig_position = [0,0,60,30]; % Make this a square

font_size_beforeafter = 12; % Axis font size for before-after plot
font_size_ROC = 12; % Axis font size for ROC
font_size_legend = 12; % Font size of legend in ROC plots

%% Plotting

figure('Units','centimeters','Position',fig_position);
fig = tiledlayout(2,6);

model_name = {'cosinor','linearAR','nonlinearAR','entropy'};
actual_model_name = {'Cosinor','Linear AR','Non-linear AR','Sample Entropy'};

for m = 1:4
    nexttile(fig,[1,1])

    %Temporary variables per iteration
    data = percept_data.kfold.(model_name{m}){hemisphere};
    chronic = nanmax(data.Responder,data.('Non-Responder'));
    
    hold on
    delta = sum([data.('Pre-DBS'),-chronic],2);
    responder_idx = find(~isnan(data.Responder));
    nonresponder_idx = find(~isnan(data.('Non-Responder')));

    scatter(repelem(x_delta,length(nonresponder_idx)),delta(nonresponder_idx),sz,'filled','MarkerEdgeColor',c_nonresponder,'MarkerFaceColor',c_nonresponder,'MarkerFaceAlpha',face_alpha);
    scatter(repelem(x_delta,length(responder_idx)),delta(responder_idx),sz,'^','filled','MarkerEdgeColor',c_responder,'MarkerFaceColor',c_responder,'MarkerFaceAlpha',face_alpha);

    text(repelem(x_delta_label,size(data,1)),delta,data.Subject,'FontSize',font_size_label);

    if max(delta(responder_idx)) < min(delta(nonresponder_idx))
        threshold = median([max(delta(responder_idx)),min(delta(nonresponder_idx))]);
        plot([x_delta-threshold_width,x_delta+threshold_width],[threshold,threshold],':k')
    elseif min(delta(responder_idx)) > max(delta(nonresponder_idx))
        threshold = median([min(delta(responder_idx)),max(delta(nonresponder_idx))]);
        plot([x_delta-threshold_width,x_delta+threshold_width],[threshold,threshold],':k')
    end
    
    ax = gca;
    if m == 4
        ylim(ylim_delta_SE)
        ylabel('\Delta Sample Entropy')
        ax.YAxis.Exponent = -2;
    else
        ylim(ylim_delta_R2/100)
        ylabel('\Delta R^2 (%)')
        set(gca,'YTickLabel',arrayfun(@num2str, 100*get(gca,'YTick'), 'UniformOutput', 0))
    end

    hold off
    title(actual_model_name{m})
    xlim(x_lims_delta)
    xticks(x_delta)
    xticklabels({'\Delta'})
    ax.FontSize = font_size_beforeafter;
    ax.TickLength(1) = 0;
    box on
end

nexttile(fig,[1,2])
hold on

plot([0,1],[0,1],'--k')
for m = 1:4
    ROC = percept_data.ROC.(model_name{m}){2,hemisphere+1};
    [FPR,TPR] = perfcurve(ROC.True,ROC.Pred_Prob,1);
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

for m = 1:4
    nexttile(fig,[1,1])
    
    %Temporary variables per iteration
    data = percept_data.kfold.(model_name{m}){hemisphere};
    chronic = nanmax(data.Responder,data.('Non-Responder'));
    
    hold on
    plot(repmat([x_preDBS,x_postDBS,NaN],1,size(data,1)),reshape([data.('Pre-DBS')';chronic';nan(1,size(data,1))],[1,size(data,1)*3]),'-k','Color',[0,0,0,line_alpha],'LineWidth',1);

    scatter(repelem(x_preDBS,size(data,1)),data.('Pre-DBS'),sz,'filled','MarkerEdgeColor',c_preDBS_outline,'MarkerFaceColor',c_preDBS,'MarkerFaceAlpha',face_alpha);
    scatter(repelem(x_postDBS,size(data,1)),data.('Non-Responder'),sz,'filled','MarkerEdgeColor',c_nonresponder,'MarkerFaceColor',c_nonresponder,'MarkerFaceAlpha',face_alpha);    
    scatter(repelem(x_postDBS,size(data,1)),data.Responder,sz,'^','filled','MarkerEdgeColor',c_responder,'MarkerFaceColor',c_responder,'MarkerFaceAlpha',face_alpha);

    text(repelem(x_preDBS_label,size(data,1)),data.('Pre-DBS'),data.Subject,'FontSize',font_size_label)
    text(repelem(x_postDBS_label,sum(isnan(data.('Pre-DBS')))),chronic(isnan(data.('Pre-DBS'))),data.Subject(isnan(data.('Pre-DBS'))),'FontSize',font_size_label)
    
    % Plot threshold line if clear demarcation exists
    if max([data.('Pre-DBS');data.('Non-Responder')]) < min(data.Responder)
        threshold = median([max([data.('Pre-DBS');data.('Non-Responder')]),min(data.Responder)]);
        plot([x_preDBS-threshold_width,x_postDBS+threshold_width],[threshold,threshold],':k')
    elseif min([data.('Pre-DBS');data.('Non-Responder')]) > max(data.Responder)
        threshold = median([min([data.('Pre-DBS');data.('Non-Responder')]),max(data.Responder)]);
        plot([x_preDBS-threshold_width,x_postDBS+threshold_width],[threshold,threshold],':k')
    end
    
    ax = gca;
    if m == 4
        ylabel('Sample Entropy')
        ylim(ylim_SE)
        ax.YAxis.Exponent = -2;
    else
        ylabel('R^2 (%)')
        ylim(ylim_R2/100)
        set(gca,'YTickLabel',arrayfun(@num2str, 100*get(gca,'YTick'), 'UniformOutput', 0))
    end

    hold off
    title(actual_model_name{m})
    xlim(x_lims_norm)
    xticks([x_preDBS,x_postDBS])
    xticklabels({'Pre-DBS','Chronic Status'})
    ax.FontSize = font_size_beforeafter;
    ax.TickLength(1) = 0;
    box on
end

nexttile(fig,[1,2])
hold on
plot([0,1],[0,1],'--k')
for m = 1:4
    ROC = percept_data.ROC.(model_name{m}){1,hemisphere+1};
    [FPR,TPR] = perfcurve(ROC.True,ROC.Pred_Prob,1);
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

end