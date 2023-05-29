%clear all
close all

circadian_heat_map;
% load('acro_no_overlap.mat')
% load('amplitude_no_overlap.mat')
% load('p_no_overlap.mat')

load('acrophase.mat')
load('amplitude.mat')
load('p.mat')

for i=1:7
comb_amp{i,1}(:,all(isnan(comb_acro{i,1}),1))=[];
comb_p{i,1}(:,all(isnan(comb_acro{i,1}),1))=[];
comb_acro{i,1}(:,all(isnan(comb_acro{i,1}),1))=[];
end

sz = 20;
% comb_acro{7,1}(151:547) = [];
% comb_amp{7,1}(151:547) = [];
% comb_p{7,1}(151:547) = [];
%comb_days{7,1}(151:157) = [];

red={[15:196];[0:35];[0:19,];[];[];[];[0:54]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
blue={[];[176:364];[95:273];[];[];[];[55:100]}; %HEALTHY days of blue from Gabriel

total_height=1;
fig=tiledlayout(total_height*total_height,5);

for j=[7,1:4]
    nexttile([total_height,1])
    
    %generate color map
    [~,red_idx]=intersect(comb_days{j,1},red{j});
    [~,blue_idx]=intersect(comb_days{j,1},blue{j});
    [~,purple_idx]=intersect(comb_days{j,1},min(comb_days{j,1}):-1);
    [~,yellow_idx]=intersect(comb_days{j,1},0:max(comb_days{j,1}));

    c_map=zeros(length(comb_days{j,1}),3);
   %c_map(purple_idx,:)=repmat([0.6,0,0.8],[length(purple_idx),1]);
    c_map([yellow_idx;purple_idx],:)=repmat([255, 215, 0]/255,[length(yellow_idx)+length(purple_idx),1]);
    c_map(red_idx,:)=repmat([0.8,0,0],[length(red_idx),1]);
    c_map(blue_idx,:)=repmat([0,0,0.8],[length(blue_idx),1]);
    
    %plot significant points
    %polarscatter(comb_acro{j,1}(comb_p{j,1}<0.05)/24*2*pi,comb_amp{j,1}(comb_p{j,1}<0.05),sz,c_map(comb_p{j,1}<0.05,:),'filled','MarkerFaceAlpha',0.7)
    polarscatter(comb_acro{j,1}(comb_p{j,1}<0.05),comb_amp{j,1}(comb_p{j,1}<0.05),sz,c_map(comb_p{j,1}<0.05,:),'filled','MarkerFaceAlpha',0.7)

    hold on

    %plot non-significant points with reduced alpha
    %polarscatter(comb_acro{j,1}(comb_p{j,1}<1)/24*2*pi,comb_amp{j,1}(comb_p{j,1}<1),sz,c_map(comb_p{j,1}<1,:),'filled','MarkerFaceAlpha',0.3)
    polarscatter(comb_acro{j,1}(comb_p{j,1}<1),comb_amp{j,1}(comb_p{j,1}<1),sz,c_map(comb_p{j,1}<1,:),'filled','MarkerFaceAlpha',0.3)

    hold off
    
    %change plot axis properties
    pax=gca;
    pax.ThetaDir='clockwise';
    pax.ThetaZeroLocation='top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
    %pax.RAxis.Label.String=['Amplitude'; '(Z-Score)'];
    pax.RAxis.Label.Position=[-5,mean(rlim)];
end
fig.Padding="tight";
saveas(gcf,'acrophase.png')
saveas(gcf,'acrophase.svg')