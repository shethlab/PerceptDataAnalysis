%load('C:\Users\Owner\Desktop\SmoothedRotatedCirc.mat');
close all

preDBSdays = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
maniadays = {[];[30:70];[0:8];[0:4];[];[]};
postDBSdays = {[];[0:31,71:999];[];[];[0:999];[]};
healthydays = {[48:100];[176:364];[95:273];[];[]};

c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;

templates = {};
for i = 1:5
    [~, indspre] = intersect(comb_days{i,1},preDBSdays{i});
    templates{i,1} = median(smoothedRotatedCircadianMatricesDecib{i,2}(:,indspre),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatricesDecib{c,2}(:,indspre),2,'omitnan'),0,std(smoothedRotatedCircadianMatricesDecib{c,2}(:,indspre),2,'omitnan')];
    
    
    [~, maniainds] = intersect(comb_days{i,1},maniadays{i});
    templates{i,2} = median(smoothedRotatedCircadianMatricesDecib{i,2}(:,maniainds),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatricesDecib{c,2}(:,maniainds),2,'omitnan'),0,std(smoothedRotatedCircadianMatricesDecib{c,2}(:,maniainds),2,'omitnan')];
    
    
    [~, postDBSinds] = intersect(comb_days{i,1},postDBSdays{i});
    templates{i,3} = median(smoothedRotatedCircadianMatricesDecib{i,2}(:,postDBSinds),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatricesDecib{c,2}(:,postDBSinds),2,'omitnan'),0,std(smoothedRotatedCircadianMatricesDecib{c,2}(:,postDBSinds),2,'omitnan')];
    
    
    [~, indshealth] = intersect(comb_days{i,1},healthydays{i});
    templates{i,4} = median(smoothedRotatedCircadianMatricesDecib{i,2}(:,indshealth),2,'omitnan');
    %+[-std(smoothedRotatedCircadianMatricesDecib{c,2}(:,indshealth),2,'omitnan'),0,std(smoothedRotatedCircadianMatricesDecib{c,2}(:,indshealth),2,'omitnan')]

end

figure;
t = tiledlayout(1,5);

for i = 1:5
    
nexttile
    polarPlotDay(templates{i,1},smoothedRotatedCircadianMatricesDecib{i,1},c_yellow);
    hold on
    %polarPlotDay(templates{i,2},smoothedRotatedCircadianMatricesDecib{i,1},'c_red');
    polarPlotDay(templates{i,3},smoothedRotatedCircadianMatricesDecib{i,1},c_orange);
    polarPlotDay(templates{i,4},smoothedRotatedCircadianMatricesDecib{i,1},c_blue);


end
%save('C:\Users\Owner\Desktop\TempsAll.mat','templates');

    