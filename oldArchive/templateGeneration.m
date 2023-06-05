
close all

preDBSdays = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
maniadays = {[];[30:69];[0:8];[0:4];[]};
postDBSdays = {[];[0:29,70:296];[];[];[0:665]};
healthydays = {[48:100];[];[176:665];[95:290];[]};

% % preDBSdays = {[-39];[-5];[-9];[-21];[-2]};
% % maniadays = {[];[];[2];[1];[]};
% % postDBSdays = {[];[266];[];[];[121]};
% % healthydays = {[63];[];[355];[190];[]};

c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;

templates = {};
for i = 1:5
    [~, indspre] = intersect(comb_days{i,1},preDBSdays{i});
    indspre=setdiff(indspre,find(isnan(comb_acro{i,1}(:,:,1))));
    templates{i,1} = median(smoothedRotatedCircadianMatrices{i,2}(:,indspre),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatrices{c,2}(:,indspre),2,'omitnan'),0,std(smoothedRotatedCircadianMatrices{c,2}(:,indspre),2,'omitnan')];
    
    
    [~, maniainds] = intersect(comb_days{i,1},maniadays{i});
    maniainds=setdiff(maniainds,find(isnan(comb_acro{i,1}(:,:,1))));
    templates{i,2} = median(smoothedRotatedCircadianMatrices{i,2}(:,maniainds),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatrices{c,2}(:,maniainds),2,'omitnan'),0,std(smoothedRotatedCircadianMatrices{c,2}(:,maniainds),2,'omitnan')];
    
    
    [~, postDBSinds] = intersect(comb_days{i,1},postDBSdays{i});
    postDBSinds=setdiff(postDBSinds,find(isnan(comb_acro{i,1}(:,:,1))));
    templates{i,3} = median(smoothedRotatedCircadianMatrices{i,2}(:,postDBSinds),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatrices{c,2}(:,postDBSinds),2,'omitnan'),0,std(smoothedRotatedCircadianMatrices{c,2}(:,postDBSinds),2,'omitnan')];
    
    
    [~, indshealth] = intersect(comb_days{i,1},healthydays{i});
    indshealth=setdiff(indshealth,find(isnan(comb_acro{i,1}(:,:,1))));
    templates{i,4} = median(smoothedRotatedCircadianMatrices{i,2}(:,indshealth),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatrices{c,2}(:,indshealth),2,'omitnan'),0,std(smoothedRotatedCircadianMatrices{c,2}(:,indshealth),2,'omitnan')]

end

figure;
t = tiledlayout(1,5);
j = 1;
for i =[1,3,4,2,5]
    
    nexttile(j)
    polarPlotDay(templates{i,1},smoothedRotatedCircadianMatrices{i,1},c_yellow);
    hold on
%nexttile(5*(1)+j)
%     polarPlotDay(templates{i,2},smoothedRotatedCircadianMatrices{i,1},c_red);
    %nexttile(5*(1)+j)
    polarPlotDay(templates{i,3},smoothedRotatedCircadianMatrices{i,1},c_orange);
    hold on

    polarPlotDay(templates{i,4},smoothedRotatedCircadianMatrices{i,1},c_blue);
    
    
j = j+1;


end
%%%%save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\TempsAllSingles.mat','templates');

figure;
t = tiledlayout(1,5);
j = 1;
for i =[1,3,4,2,5]
    
    nexttile(j)
    plot(templates{i,1}-mean(templates{i,1},'omitnan'),'Color',c_yellow,'LineWidth',2);
    title(smoothedRotatedCircadianMatrices{i,1});
    hold on
   % nexttile(5*(1)+j)
   plot(templates{i,2}-mean(templates{i,2},'omitnan'),'Color',c_red,'LineWidth',2);
    %nexttile(5*(1)+j)

    plot(templates{i,3}-mean(templates{i,3},'omitnan'),'Color',c_orange,'LineWidth',2);
    hold on
    plot(templates{i,4}-mean(templates{i,4},'omitnan'),'Color',c_blue,'LineWidth',2);
    title(smoothedRotatedCircadianMatrices{i,1});
    linkaxes
    
j = j+1;


end