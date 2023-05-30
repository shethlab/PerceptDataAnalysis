load('C:\Users\Owner\Desktop\SmoothedRotatedCirc.mat');
preDBSdays = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
postDBSdays = {[0:14,196:999];[36:94];[20:94];[0:999];[0:999];[0:999];[0:54]};
healthydays = {[];[176:364];[95:273];[];[];[];[55:100]};

templates = {};
for i = 1:7
    [~, indspre] = intersect(comb_days{i,1},preDBSdays{i});
    templates{i,1} = mean(smoothedRotatedCircadianMatrices{i,2}(:,indspre),2,'omitnan');
    [~, indshealth] = intersect(comb_days{i,1},healthydays{i});
    templates{i,2} = mean(smoothedRotatedCircadianMatrices{i,2}(:,indshealth),2,'omitnan');
    [~, postDBSinds] = intersect(comb_days{i,1},postDBSdays{i});
    templates{i,3} = mean(smoothedRotatedCircadianMatrices{i,2}(:,postDBSinds),2,'omitnan');
end

figure;
t = tiledlayout(1,7);
for i = 1:7
    nexttile

    polarPlotDay(templates{i,1},smoothedRotatedCircadianMatrices{i,1},'yellow');
    hold on
    polarPlotDay(templates{i,2},smoothedRotatedCircadianMatrices{i,1},'blue');
    polarPlotDay(templates{i,3},smoothedRotatedCircadianMatrices{i,1},'#D95319');
end
save('C:\Users\Owner\Desktop\TempsAll.mat','templates');

    