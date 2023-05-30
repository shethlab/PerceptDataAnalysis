figure;
tiledlayout(7,1);
q = 13;
% load('C:\Users\Owner\Desktop\SmoothedRotatedCirc.mat');
% save('C:\Users\Owner\Desktop\TempsAll.mat','templates')
for i = 1:7
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
        plot(comb_days{i,1},d(3,:),'Color','#D95319');
    end
    
    legend({'Distance From Sick','Distance From Healthy'});
    title(smoothedRotatedCircadianMatrices{i,1});

end
linkaxes([h{:}],'y')
