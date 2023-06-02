%% Dists

dayspre = {[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1];[-100:-1]};
%%dayspre = {[-5:-1];[-5:-1];[-5:-1];[-5:-1];[-5:-1]}

dayspost = {[48:100];[0:29,70:999];[176:364];[95:273];[0:999];[48:100]};
%%dayspost = {[0:4];[0:4];[0:4];[0:4];[0:4];};

distspreacro = {};
distspostacro = {};
distspreamp = {};
distspostamp = {};
c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_orange = [127,63,152]/255;
c_yellow = [255,215,0]/255;
for i = 1:5
    for j = 2:3
        [~, indspre] = intersect(comb_days2{i,1},dayspre{i});
        distspreacro{i,j} = comb_acro2{i,1}(indspre);
        distspreamp{i,j} = comb_amp2{i,1}(indspre);
        [~, indspost] = intersect(comb_days2{i,1},dayspost{i});
        distspostacro{i,j} = comb_acro2{i,1}(indspost);
        distspostamp{i,j} = comb_amp2{i,1}(indspost);
    end
end

%% Acro
p = {'001';'002';'004';'005';'006'};
figure;
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        boxplot([distspreacro{i,2},distspostacro{i,2}],[ones(length(distspreacro{i,2}),1);2*ones(length(distspostacro{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
    else
        boxplot([distspreacro{i,2},distspostacro{i,2}],[ones(length(distspreacro{i,2}),1);2*ones(length(distspostacro{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
    end
    [~,p{i,2}] = ttest2(distspreacro{i,2},distspostacro{i,2});
    title(comb_LFP_raw_matrix{i,1})
end
title(t,'Acrophase')


%% Amp

figure;
t =tiledlayout(1,5);
for i = 1:5
    nexttile
    if i ==2 || i ==5
        boxplot([distspreamp{i,2},distspostamp{i,2}],[ones(length(distspreamp{i,2}),1);2*ones(length(distspostamp{i,2}),1)]','Colors',[c_yellow;c_orange],'Labels',{'Pre DBS','Long Term Status'});
    else
        boxplot([distspreamp{i,2},distspostamp{i,2}],[ones(length(distspreamp{i,2}),1);2*ones(length(distspostamp{i,2}),1)]','Colors',[c_yellow;c_blue],'Labels',{'Pre DBS','Long Term Status'});
    end
    title(comb_LFP_raw_matrix{i,1})
    [~,p{i,3}] = ttest2(distspreamp{i,2},distspostamp{i,2});
end
title(t,'Amplitude')

