%% Generate Figure 1
%% Data Located in streamsplot.mat
colors = {[230 145 60]/255,[0 162 89]/255};
band=[8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79];
pats = {'P001','P002','P004','P005','P006','P007','P008'};
figure('Renderer', 'painters', 'PaperUnits','centimeters','PaperPosition',[0,0,8.7,8.85]);

s = 1;
for i = [3,1,4,5,2,6,7]
    pt = streams{i};
    %% Compute and Plot spectrum for each hemisphere
    for j=1:length(pt)
        hold on
        if isempty(pt{j})
            amp = [];
            freq = [];
        else
            [amp,freq] = computeSpectrum(pt{j});
        end
        if i ==7
            s = 8;
        end
        ax = subplot(3,3,s);
        plot(freq,20*log10(amp),'Color',colors{j});
        hold on
        xline(band(i))
        title(ax,pats{i})
        ax.TitleHorizontalAlignment = 'left';
    end

    box off

    %% Plot Limits and Gray Patch on Recording Band
    xlim([0,60])
    x = [band(i)-2.5 band(i)+2.5 band(i)+2.5 band(i)-2.5];
    y = [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)];
    patch(x,y,[.8 .8 .8],'EdgeColor','none')
    set(gca,'children',flipud(get(gca,'children')))
    s = s+1;

end


