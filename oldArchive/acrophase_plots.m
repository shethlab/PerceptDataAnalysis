%clear all
close all

%% User inputs
sz = 10; % marker size
load([loaddir loadfile])
%%
    
% patient initial list
% pt_names=[{'SR'},{'MR'},{'KK'},{'CF'},{'CD'}];
% GPi plotting exceptions
if target==1
    pt_range = [1:5];
else
    pt_range = [1,2];
end

%colors
c_red = [255,0,0]/255;
c_blue = [0,0,255]/255;
c_purple = [127,63,152]/255;
c_yellow = [255,215,0]/255;
c_white = [255,255,255]/255;

if target==1
    red={[];[30:69];[0:8];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
    blue={[48:100];[];[176:665];[95:290];[]}; %HEALTHY days of blue from Gabriel
    purple={[0:47];[0:29,70:296];[9:175];[5:94];[0:396]};
else
    red={[];[0:4];[]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
    blue={[48:100];[95:290];[]}; %HEALTHY days of blue from Gabriel
    purple={[0:47];[5:94];[0:396]};
end
total_height=5;
figure('Position',[0,0,750,200])
for j=pt_range
    nexttile([total_height,1])
    
    %generate color map
    [~,red_idx]=intersect(comb_days{j,hem},red{j});
    [~,blue_idx]=intersect(comb_days{j,hem},blue{j});
    [~,yellow_idx]=intersect(comb_days{j,hem},min(comb_days{j,hem}):-1);
    [~,purple_idx]=intersect(comb_days{j,hem},purple{j});

    c_map=zeros(length(comb_days{j,hem}),3);
    c_map(purple_idx,:)=repmat(c_purple,[length(purple_idx),1]);
    c_map(yellow_idx,:)=repmat(c_yellow,[length(yellow_idx),1]);
    c_map(red_idx,:)=repmat(c_red,[length(red_idx),1]);
    c_map(blue_idx,:)=repmat(c_blue,[length(blue_idx),1]);

    
    
    %plot significant points
    polarscatter(comb_acro{j,hem}(comb_p{j,hem}<0.05),comb_amp{j,hem}(comb_p{j,hem}<0.05),sz,c_map(comb_p{j,hem}<0.05,:),'filled','MarkerFaceAlpha',0.7)

    hold on

    %plot non-significant points with reduced alpha
    polarscatter(comb_acro{j,hem}(comb_p{j,hem}>=0.05),comb_amp{j,hem}(comb_p{j,hem}>=0.05),sz,c_map(comb_p{j,hem}>=0.05,:),'filled','MarkerFaceAlpha',0.3)
    
    hold off
   
    %hide purple dots for responders
    if (j==1 || j==3 || j== 4 || j==2) && ~isempty(purple_idx)
        comb_p{j,hem}(purple_idx(1):purple_idx(end))=0.05;
    polarscatter(comb_acro{j,hem}(comb_p{j,hem}<0.05),comb_amp{j,hem}(comb_p{j,hem}<0.05),sz,c_map(comb_p{j,hem}<0.05,:),'filled','MarkerFaceAlpha',0.7)

    hold on

    polarscatter(comb_acro{j,hem}(comb_p{j,hem}>0.05),comb_amp{j,hem}(comb_p{j,hem}>0.05),sz,c_map(comb_p{j,hem}>0.05,:),'filled','MarkerFaceAlpha',0.3)
    
    hold off
    else
    end

    %change plot axis properties
    pax=gca;
    pax.ThetaDir='clockwise';
    pax.ThetaZeroLocation='top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
%     pax.RAxis.Label.String=['Amplitude'; '(Z-Score)'];
%     pax.RAxis.Label.Position=[-5,mean(rlim)];
    subtitle(strcat('P',comb_LFP_raw_matrix(j,1)));
    pax.FontSize=8;
    pax.RAxisLocation=0;
    if j==1
        rlim(pax,[0,1.2]);
        rticks(pax,[0,0.3,0.6,0.9]);
        rticklabels(pax,[0,0.3,0.6,0.9]);
    else
        rlim(pax,[0,1]);
        rticks(pax,[0,0.2,0.4,0.6,0.8]);
        rticklabels(pax,[0,0.2,0.4,0.6,0.8]);
    end
end
% saveas(gcf, savedir);
