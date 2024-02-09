%% This function is used to create circular polar plots of cosinor amplitude
% vs acrophase. This function has three required inputs and one optional:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this function is the circadian_calc function, which
%       creates the appropriately-formatted data structure. This structure 
%       must contain four fields called "days," "acrophase," "amplitude,"
%       and "cosinor_p."
%   2. hemisphere: the hemisphere of data to display. Set to 1 for left or
%       2 for right.
%   3. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   5 (optional). is_demo: a flag which, when set to 1, signals that the
%       demo dataset (demo_data.mat) is being run. This plots only the
%       first five patients to align with the patients displayed in the
%       manuscript Figure 2 and S1.
%
% This function outputs an n x 1 plot of cosinor amplitude (radial axis) vs
% acrophase (angular axis), where n is the number of subjects. Points
% corrseponding to days which resulted in non-significant cosinor fits are
% plotted with reduced transparency.

function plot_cosinor(percept_data,hemisphere,zone_index,is_demo)

%% Detailed Adjustable Inputs

sz = 6; % Marker size
sig_point_alpha = 0.7; % Transparency of points with significant cosinor fit
nonsig_point_alpha = 0.3; % Transparency of points with non-significant cosinor fit
fig_width = 3.43; % Width of figure in cm
fig_height = 12; % Height of figure in cm per patient (will be multiplied by number of patients)
font_size = 4.5; % Font size

%Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [255,215,0]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone

c_preDBS_outline = [128,128,128]/255; % Color of pre-DBS outline
c_postDBS_outline = [255,185,0]/255; % Color of post-DBS outline for non-responders
outline_alpha = 0.1; % Transparency level of pre/post-DBS outlines

%% Plotting

if exist('is_demo','var') && is_demo == 1 % For figure 2 & S1 demo
    total_height = 5;
else
    total_height = size(percept_data.days,1);
end
figure('Units','centimeters','Position',[0,0,fig_width,fig_height*total_height],'Color','w');

for j = 1:total_height
    nexttile([1,total_height])

    %Temporary variables per iteration
    acro = percept_data.acrophase{j,hemisphere+1};
    amp = percept_data.amplitude{j,hemisphere+1};
    p = percept_data.cosinor_p{j,hemisphere+1};
    days = percept_data.days{j,hemisphere+1};
    
    %Find indices of each zone
    pre_DBS_idx = find(days < 0)';
    [~,non_responder_idx] = intersect(days,zone_index.non_responder{j});
    [~,responder_idx] = intersect(days,zone_index.responder{j});
    [~,manic_idx] = intersect(days,zone_index.hypomania{j});
    keep_idx = ismember(1:length(days),[pre_DBS_idx; non_responder_idx; responder_idx; manic_idx]);
    
    %Generate RGB colormap for each index of data
    c_map = zeros(length(days),3);
    c_map(pre_DBS_idx,:) = repmat(c_preDBS,[length(pre_DBS_idx),1]);
    c_map(responder_idx,:) = repmat(c_responder,[length(responder_idx),1]);
    c_map(non_responder_idx,:) = repmat(c_nonresponder,[length(non_responder_idx),1]);
    c_map(manic_idx,:) = repmat(c_mania,[length(manic_idx),1]);

    c_map_outlines = c_map;
    c_map_outlines(non_responder_idx,:) = repmat([0,0,0],[length(non_responder_idx),1]);
    
    %Plot significant points (pre-DBS)
    polarscatter(acro(p < 0.05 & keep_idx & days < 0),amp(p < 0.05 & keep_idx & days < 0),sz,c_map(p < 0.05 & keep_idx & days < 0,:),'filled','MarkerFaceAlpha',sig_point_alpha)
    hold on
    %Plot non-significant points (pre-DBS)
    polarscatter(acro(p >= 0.05 & keep_idx & days < 0),amp(p >= 0.05 & keep_idx & days < 0),sz,c_map(p >= 0.05 & keep_idx & days < 0,:),'filled','MarkerFaceAlpha',nonsig_point_alpha)
    %Plot outlines
    polarscatter(acro(keep_idx & days < 0),amp(keep_idx & days < 0),sz-1,'MarkerEdgeColor',c_preDBS_outline,'MarkerEdgeAlpha',outline_alpha)

    %Plot significant points (post-DBS)
    polarscatter(acro(p < 0.05 & keep_idx & days >= 0),amp(p < 0.05 & keep_idx & days >= 0),sz,c_map(p < 0.05 & keep_idx & days >= 0,:),'filled','MarkerFaceAlpha',sig_point_alpha)
    %Plot non-significant points (post-DBS)
    polarscatter(acro(p >= 0.05 & keep_idx & days >= 0),amp(p >= 0.05 & keep_idx & days >= 0),sz,c_map(p >= 0.05 & keep_idx & days >= 0,:),'filled','MarkerFaceAlpha',nonsig_point_alpha)
    %Plot outlines
    polarscatter(acro(non_responder_idx),amp(non_responder_idx),sz-1,'MarkerEdgeColor',c_postDBS_outline,'MarkerEdgeAlpha',outline_alpha)
    hold off

    %Change plot axis properties
    pax = gca;
    pax.ThetaDir = 'clockwise';
    pax.ThetaZeroLocation = 'top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
    thetaticklabels({})
    pax.RAxis.Label.String = ['Amplitude'; '(Z-Score)'];
    pax.RAxis.Label.Position = [-5,mean(rlim)];
    subtitle(percept_data.days(j,1));
    pax.FontSize = font_size;
    pax.RAxisLocation = 0;
end

end