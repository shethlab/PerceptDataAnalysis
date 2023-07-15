% close all;

loaddir='/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/';
savedir = [loaddir,'final_figures/ROC_updated.svg'];
filename = 'roc_curves.xlsx';
%load data
P001 = readtable([loaddir, filename],'Sheet','PT102');
P002 = readtable([loaddir, filename],'Sheet','PT105');
P004 = readtable([loaddir, filename],'Sheet','PT101');
P005 = readtable([loaddir, filename],'Sheet','PT103');
P006 = readtable([loaddir, filename],'Sheet','PT104');
% P001 = readtable([loaddir, filename],'Sheet','PT001');
% P002 = readtable([loaddir, filename],'Sheet','PT002');
% P004 = readtable([loaddir, filename],'Sheet','PT004');
% P005 = readtable([loaddir, filename],'Sheet','PT005');
% P006 = readtable([loaddir, filename],'Sheet','PT006');

figure('Units','inches','Position',[0 0 3.15 3]);
c_blue = [50,50,255]/255;
c_blue2 = [105,160,255]/255;
c_blue3 = [130,200,255]/255;
c_purple = [127,63,152]/255;
c_purple2 = [200,160,255]/255;
pt_names = {'P101','P102','P103','P104','P105'};
hold on
plot(P004.FPR,P004.TPR,'LineWidth',1,'Color',c_blue);
plot(P001.FPR,P001.TPR,'LineWidth',1,'Color',c_blue2);
plot(P005.FPR,P005.TPR,'LineWidth',1,'Color',c_blue3);
plot(P006.FPR,P006.TPR,'LineWidth',1,'Color',c_purple);
plot(P002.FPR,P002.TPR,'LineWidth',1,'Color',c_purple2);
plot([0 1],[0 1], 'LineWidth',1,'LineStyle','--','Color','black');
hold off
ylabel('True Positive Rate');
xlabel('False Positive Rate');
legend(pt_names,'FontSize',9 ,'Location','southeast');
set(gca,'FontSize',9);
% saveas(gcf,savedir)