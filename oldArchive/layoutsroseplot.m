close all
rotated3bin = binneddata{4,2};
rotated3bin(:,all(isnan(rotated3bin))) = [];
bin006LHtemp = binned{4,2};
figct = 1;
for i = 1:6
    figure;
    t = tiledlayout(6,6);
    for j = 1:6  
        for k = 1:6
            num = 36*(i-1)+6*(j-1)+k;
            if num>length(comb_days{4,1})
                continue
            end
            nexttile;

            polarplot(theta,bin006LHtemp);
            hold on
            polarplot(theta,rotated3bin(:,num));
            title(string(comb_days{4,1}(num)));
            figct = figct+1;
            rlim([-.75,2])
            pax=gca;
            pax.ThetaDir='clockwise';
            pax.ThetaZeroLocation='top';
            thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
        end
    end
end

%%
rotated3bin = binneddata{4,2};
rotated3bin(:,all(isnan(rotated3bin))) = [];
bin005LHtemp = binned{4,2};

distances =[];
for i =1:210
    A = rotated3bin(:,i);
    distances(i) = Distance(A,bin005LHtemp);
end

scatter(comb_days{3,1},distances);
