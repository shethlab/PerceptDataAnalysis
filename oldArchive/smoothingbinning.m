theta = 0:2*pi/144:143*2*pi/144 ;

%%
smoothed = temp_preDBS;
for i = 1:6
    smoothed{i,2} = smooth([smoothed{i,2}; smoothed{i,2}],6);
    smoothed{i,2} = smoothed{i,2}(1:length(temp_preDBS{i,2}));
    smoothed{i,3} = smooth([smoothed{i,3}; smoothed{i,3}],6);
    smoothed{i,3} = smoothed{i,3}(1:length(temp_preDBS{i,3}));
end
%%
binned = temp_preDBS;
for i = 1:6
    binned{i,2} = [binned{i,2}(end-2:end);binned{i,2}(1:end-3)];
    binned{i,3} = [binned{i,3}(end-2:end);binned{i,3}(1:end-3)]; 
    for j = 1:24
        binned{i,2}(6*(j-1)+1:6*j) = median(binned{i,2}(6*(j-1)+1:6*j));
        binned{i,3}(6*(j-1)+1:6*j) = median(binned{i,3}(6*(j-1)+1:6*j));
    end
end
%%
binneddata = rots;
for i = 1:6
    binneddata{i,2} = [binneddata{i,2}(end-2:end,:);binneddata{i,2}(1:end-3,:)];
    binneddata{i,3} = [binneddata{i,3}(end-2:end,:);binneddata{i,3}(1:end-3,:)]; 
    for j = 1:24
        binneddata{i,2}(6*(j-1)+1:6*j,:) = repmat(median(binneddata{i,2}(6*(j-1)+1:6*j,:),'omitnan'),[6 1]);
        binneddata{i,3}(6*(j-1)+1:6*j,:) = repmat(median(binneddata{i,3}(6*(j-1)+1:6*j,:),'omitnan'),[6 1]);
    end
end
%%
for i =1:6
    figure;
    t = tiledlayout(1,2);
    nexttile;
    polarplot(theta,binned{i,2})
    rlim([-.75,2])
    pax=gca;
    pax.ThetaDir='clockwise';
    pax.ThetaZeroLocation='top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
    nexttile;
    polarplot(theta,binned{i,3})
    rlim([-.75,2])
    title(t,temp_preDBS{i,1})
    pax=gca;
    pax.ThetaDir='clockwise';
    pax.ThetaZeroLocation='top';
    thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
end