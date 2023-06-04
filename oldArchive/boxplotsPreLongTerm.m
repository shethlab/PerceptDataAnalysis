%% Dists
%close all
box = 1;
useAnthonys = 1;
chronic = 1;
if chronic
    dayspre = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
    dayspost = {[48:100];[0:29,70:999];[176:665];[95:290];[0:396]};
    figsave = 'C:\Users\Owner\Desktop\Percept Runnig Circadian Data\Figures\chronicrolling\';
else
    day = 5;
    dayspre = {[-day:-1];[-day:-1];[-day:-1];[-day:-1];[-day:-1]}
    dayspost = {[1:day];[1:day];[1:day];[1:day];[1:day];};
    figsave = 'C:\Users\Owner\Desktop\Percept Runnig Circadian Data\Figures\pm9rolling\';
end

distspreacro = {};
distspostacro = {};

distspreamp = {};
distspostamp = {};

distsprecircmean = {};
distspostcircmean = {};

distsprecircvar = {};
distspostcircvar = {};

distspreentropy = {};
distspostentropy = {};


c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;
for i = 1:5
    for j = 2:3
        [~, indspre] = intersect(comb_days{i,1},dayspre{i});
        [~, indspost] = intersect(comb_days{i,1},dayspost{i});
        
        if ~chronic
            indspre = indspre(end-min(length(indspre),length(indspost))+1:end);
            indspost = indspost(1:min(length(indspre),length(indspost)));
        end

        distspreacro{i,j} = comb_acro{i,1}(:,indspre,1);
        distspreamp{i,j} = comb_amp{i,1}(:,indspre,1);
        distsprecircmean{i,2} = comb_circmean{i,1}(indspre);
        distsprecircvar{i,2} = comb_circvar{i,1}(indspre);
        distspreentropy{i,2} = comb_circentropy{i,1}(indspre);
        
        distspostacro{i,j} = comb_acro{i,1}(:,indspost,1);
        distspostamp{i,j} = comb_amp{i,1}(:,indspost,1);
        distspostcircmean{i,2} = comb_circmean{i,1}(indspost);
        distspostcircvar{i,2} = comb_circvar{i,1}(indspost);
        distspostentropy{i,2} = comb_circentropy{i,1}(indspost);
    end
end

%% Acro
p = {'001';'002';'004';'005';'006'};
f = figure('Position', get(0, 'Screensize'));
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        if box
            boxplot([distspreacro{i,2},distspostacro{i,2}],[ones(length(distspreacro{i,2}),1);2*ones(length(distspostacro{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreacro(i,2),distspostacro(i,2)],'UniformOutput',false),'bw',.3,'facecolor',[c_yellow;c_orange],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    else
        if box
            boxplot([distspreacro{i,2},distspostacro{i,2}],[ones(length(distspreacro{i,2}),1);2*ones(length(distspostacro{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreacro(i,2),distspostacro(i,2)],'UniformOutput',false),'bw',.3,'facecolor',[c_yellow;c_blue],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    end

    [~,p{i,2}] = ttest2(distspreacro{i,2},distspostacro{i,2},'VarType','unequal');
    title(p{i,1})
end
linkaxes
title(t,'Acrophase')
saveas(f,strcat(figsave,'acroBox.png'));
close all
%% Amp

f = figure('Position', get(0, 'Screensize'));
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        if box
            boxplot([distspreamp{i,2},distspostamp{i,2}],[ones(length(distspreamp{i,2}),1);2*ones(length(distspostamp{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreamp(i,2),distspostamp(i,2)],'UniformOutput',false),'bw',.05,'facecolor',[c_yellow;c_orange],'xlabel',{'Pre DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end

    else
        if box
            boxplot([distspreamp{i,2},distspostamp{i,2}],[ones(length(distspreamp{i,2}),1);2*ones(length(distspostamp{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreamp(i,2),distspostamp(i,2)],'UniformOutput',false),'bw',.05,'facecolor',[c_yellow;c_blue],'xlabel',{'Pre DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end

    end
    title(p{i,1})
    [~,p{i,3}] = ttest2(distspreamp{i,2},distspostamp{i,2},'VarType','unequal');
end
linkaxes
title(t,'Amplitude')
saveas(f,strcat(figsave,'ampBox.png'));
close all
if useAnthonys
%% Circ Mean

f = figure('Position', get(0, 'Screensize'));
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        if box
            boxplot([distsprecircmean{i,2},distspostcircmean{i,2}],[ones(length(distsprecircmean{i,2}),1);2*ones(length(distspostcircmean{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distsprecircmean(i,2),distspostcircmean(i,2)],'UniformOutput',false),'bw',.5,'facecolor',[c_yellow;c_orange],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    else
        if box
            boxplot([distsprecircmean{i,2},distspostcircmean{i,2}],[ones(length(distsprecircmean{i,2}),1);2*ones(length(distspostcircmean{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distsprecircmean(i,2),distspostcircmean(i,2)],'UniformOutput',false),'bw',.5,'facecolor',[c_yellow;c_blue],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    end

    [~,p{i,4}] = ttest2(distsprecircmean{i,2},distspostcircmean{i,2},'VarType','unequal');
    title(p{i,1})
end
linkaxes
title(t,'Circular Mean')
saveas(f,strcat(figsave,'circMeanBox.png'));
close all
%% Circ Var

f = figure('Position', get(0, 'Screensize'));
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        if box
            boxplot([distsprecircvar{i,2},distspostcircvar{i,2}],[ones(length(distsprecircvar{i,2}),1);2*ones(length(distspostcircvar{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distsprecircvar(i,2),distspostcircvar(i,2)],'UniformOutput',false),'bw',.05,'facecolor',[c_yellow;c_orange],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    else
        if box
            boxplot([distsprecircvar{i,2},distspostcircvar{i,2}],[ones(length(distsprecircvar{i,2}),1);2*ones(length(distspostcircvar{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distsprecircvar(i,2),distspostcircvar(i,2)],'UniformOutput',false),'bw',.05,'facecolor',[c_yellow;c_blue],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    end

    [~,p{i,5}] = ttest2(distsprecircvar{i,2},distspostcircvar{i,2},'VarType','unequal');
    title(p{i,1})
end
%linkaxes

title(t,'Circular Variance')
saveas(f,strcat(figsave,'circVarBox.png'));
close all
%% Entropy

f = figure('Position', get(0, 'Screensize'));
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        if box
            boxplot([distspreentropy{i,2},distspostentropy{i,2}],[ones(length(distspreentropy{i,2}),1);2*ones(length(distspostentropy{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreentropy(i,2),distspostentropy(i,2)],'UniformOutput',false),'bw',.01,'facecolor',[c_yellow;c_orange],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    else
        if box
            boxplot([distspreentropy{i,2},distspostentropy{i,2}],[ones(length(distspreentropy{i,2}),1);2*ones(length(distspostentropy{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
            set(gca,'FontSize',12);
        else
            violin(cellfun(@transpose,[distspreentropy(i,2),distspostentropy(i,2)],'UniformOutput',false),'bw',.01,'facecolor',[c_yellow;c_blue],'xlabel',{'Pre-DBS','Long Term Status'},'medc',[],'plotlegend',0);
            xticks([1,2]);
            xticklabels({'Pre DBS','Long Term Status'});
        end
    end

    [~,p{i,6}] = ttest2(distspreentropy{i,2},distspostentropy{i,2},'VarType','unequal');
    title(p{i,1})
end
linkaxes
title(t,'Entropy')
saveas(f,strcat(figsave,'entropyBox.png'));
close all

pvals = cell2table(p,'VariableNames',{'Patient','Acrophase','Amplitude','Circular Mean','Circular Variance','Sample Entropy'});

end
if chronic
    save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\New Stats\pvaluestatsrolling.mat','pvals');
else
    save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\New Stats\pvaluestatsdayrolling.mat','pvals');
end

