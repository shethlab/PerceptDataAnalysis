%% Dists
%close all
box = 1;
useAnthonys = 1;
%%dayspre = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
dayspre = {[-5:-1];[-5:-1];[-5:-1];[-5:-1];[-5:-1]}
%%dayspost = {[48:100];[0:29,70:999];[176:665];[95:290];[0:396]};
dayspost = {[1:5];[1:5];[1:5];[1:5];[1:5];};

distsprecircvar = {};
distspostcircvar = {};
c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;
for i = 1:5
    [~, indspre] = intersect(comb_days{i,1},dayspre{i});
    distsprecircvar{i,2} = circvars{i,1}(:,indspre,1);
    [~, indspost] = intersect(comb_days{i,1},dayspost{i});
    distspostcircvar{i,2} = circvars{i,1}(:,indspost,1);
end
%%
p = {'001';'002';'004';'005';'006'};
figure;
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

    [~,p{i,2}] = ttest2(distsprecircvar{i,2},distspostcircvar{i,2});
    title(p{i,1})
end
%linkaxes
title(t,'Circular Variance')