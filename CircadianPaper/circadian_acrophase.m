function [] = circadian_acrophase(data,hemisphere,zone_index)

%% Detailed Adjustable Inputs

sz = 10; % Marker size
sig_point_alpha = 0.7; % Transparency of points with significant cosinor fit
nonsig_point_alpha = 0.3; % Transparency of points with non-significant cosinor fit
fig_position = [0,0,200,750]; % Position of figure in pixels
font_size = 8; % Font size

%Color values (RGB 0-1)
c_mania = [255,0,0]/255; % Color of hypomania zone
c_responder = [0,0,255]/255; % Color of chronic responder zone
c_nonresponder = [127,63,152]/255; % Color of chronic non-responder zone
c_preDBS = [255,215,0]/255; % Color of pre-DBS zone

%% Plotting

figure('Position',fig_position)
total_height = size(data.days,1);

for j = 1:size(data.days,1)
    nexttile([1,total_height])

    %Temporary variables per iteration
    acro = data.acrophase{j,hemisphere+1};
    amp = data.amplitude{j,hemisphere+1};
    p = data.cosinor_p{j,hemisphere+1};
    days = data.days{j,hemisphere+1};
    
    %Find indices of each zone
    pre_DBS_idx = find(days < 0);
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
    
    %Plot significant points
    polarscatter(acro(p < 0.05 & keep_idx),amp(p < 0.05 & keep_idx),sz,c_map(p < 0.05 & keep_idx,:),'filled','MarkerFaceAlpha',sig_point_alpha)
    hold on

    %Plot non-significant points with reduced alpha
    polarscatter(acro(p >= 0.05 & keep_idx),amp(p >= 0.05 & keep_idx),sz,c_map(p >= 0.05 & keep_idx,:),'filled','MarkerFaceAlpha',nonsig_point_alpha)   
    hold off

    %Change plot axis properties
    pax = gca;
    pax.ThetaDir = 'clockwise';
    pax.ThetaZeroLocation = 'top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
%     pax.RAxis.Label.String = ['Amplitude'; '(Z-Score)'];
%     pax.RAxis.Label.Position = [-5,mean(rlim)];
    subtitle(data.LFP_raw_matrix(j,1));
    pax.FontSize = font_size;
    pax.RAxisLocation = 0;
end

end