figure;
tiledlayout(5,1);
q = 13;

red={[15:196];[0:35];[0:19];[];[];[];[0:54]}; %HYPOMANIA+DISINHIBITION days of red from Gabriel
blue={[];[176:364];[95:273];[];[];[];[55:100]}; %HEALTHY days of green from Gabriel
% load('C:\Users\Owner\Desktop\SmoothedRotatedCirc.mat');
% save('C:\Users\Owner\Desktop\TempsAll.mat','templates')
for i = [7,1:4]
    %generating colormap
    [~,red_idx]=intersect(comb_days{i,1},red{i});
    [~,blue_idx]=intersect(comb_days{i,1},blue{i});
    [~,purple_idx]=intersect(comb_days{i,1},min(comb_days{i,1}):-1);
    [~,yellow_idx]=intersect(comb_days{i,1},0:max(comb_days{i,1}));

    c_map=zeros(length(comb_days{i,1}),3);
    c_map(purple_idx,:)=repmat([0.6,0,0.8],[length(purple_idx),1]);
    %c_map([yellow_idx;purple_idx],:)=repmat([0.95,0.95,0],[length(yellow_idx)+length(purple_idx),1]);
    c_map(yellow_idx,:)=repmat([0.9,0.9,0],[length(yellow_idx),1]);
    c_map(red_idx,:)=repmat([0.8,0,0],[length(red_idx),1]);
    c_map(blue_idx,:)=repmat([0,0,0.8],[length(blue_idx),1]);
        
    template1 = templates{i,1};
    template2 = templates{i,2};
    template3 = templates{i,3};
    d=[];
    for j = 1:width(comb_days{i,1})
        [~,window] = intersect(comb_days{i,1},comb_days{i,1}(j)-q:comb_days{i,1}(j));
        if length(window) <q+1
            d(1,j) = nan;
            d(2,j) = nan;
            d(3,j) = nan;
            continue
        end
        %window = j;
        windowdata = mean(smoothedRotatedCircadianMatrices{i,2}(:,window),2,'omitnan');
        d(1,j) = distanceMetric(windowdata,template1);
        d(2,j) = distanceMetric(windowdata,template2);
        d(3,j) = distanceMetric(windowdata,template3);


    end
    h{i}=nexttile;
   
    plot(comb_days{i,1},d(1,:),'Color',[0.9 0.9 0]);
    hold on;
    plot(comb_days{i,1},d(2,:),'blue');
    if all(isnan(d(2,:)))
        plot(comb_days{i,1},d(3,:),'Color',[1,0.7,0]);
    end
    try
    patch('Faces',[1,2,3,4],'Vertices',[comb_days{i,1}(purple_idx(1)),70;comb_days{i,1}(purple_idx(end))+1,70;comb_days{i,1}(purple_idx(end))+1,60;comb_days{i,1}(purple_idx(1)),60],'FaceColor',[0.9,0.9,0],'EdgeColor','none')
    end
    try
    if i==1 | i==4
        patch('Faces',[1,2,3,4],'Vertices',[comb_days{i,1}(yellow_idx(1)),70;comb_days{i,1}(yellow_idx(end))+1,70;comb_days{i,1}(yellow_idx(end))+1,60;comb_days{i,1}(yellow_idx(1)),60],'FaceColor',[1,0.7,0],'EdgeColor','none')
    end
    end
    try
    patch('Faces',[1,2,3,4],'Vertices',[comb_days{i,1}(red_idx(1)),70;comb_days{i,1}(red_idx(end))+1,70;comb_days{i,1}(red_idx(end))+1,60;comb_days{i,1}(red_idx(1)),60],'FaceColor',[0.8,0,0],'EdgeColor','none')
    end
    try
    patch('Faces',[1,2,3,4],'Vertices',[comb_days{i,1}(blue_idx(1)),70;comb_days{i,1}(blue_idx(end))+1,70;comb_days{i,1}(blue_idx(end))+1,60;comb_days{i,1}(blue_idx(1)),60],'FaceColor',[0,0,0.8],'EdgeColor','none')
    end

    legend({'Distance From Sick','Distance From Healthy'});
    title(smoothedRotatedCircadianMatrices{i,1});

    if i==4
        xlabel('Days Since DBS On')
    end

end
linkaxes([h{:}],'y')
ylim([0,70])