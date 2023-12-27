%% Generate Figure 1
%% Data Located in streamsplot.mat
colors = {[230 145 60]/255,[0 162 89]/255};
band=[8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79];
pats = {'B001','B002','B004','B005','B006','B007','B008','B009','B010','U001','U002','U003'};
figure('Renderer', 'painters', 'Units','centimeters','Position',[0,0,16,12],'Color','w');

t = tiledlayout(4,3);


for i = 1:12
    pt = streams{i};
                ax = nexttile;

    if i <10
        %% Compute and Plot spectrum for each hemisphere
        for j=1:length(pt)
            hold on
            if isempty(pt{j})
                amp = [];
                freq = [];
            else
                [amp,freq] = computeSpectrum(pt{j});
            end
            plot(freq,20*log10(amp),'Color',colors{j});
            hold on
            xline(band(i))
            title(ax,pats{i})
            ax.TitleHorizontalAlignment = 'left';

        end
    else
        for j=1:length(pt)
            if isempty(pt{j})
                amp = [];
                freq = [];
            else
                amp = pt{j};
            end
            plot(frequency,20*log10(amp),'Color',colors{j});
            hold on
            xline(band(i))
            title(ax,pats{i})
            ax.TitleHorizontalAlignment = 'left';
        end
    end
    box off
        axis square
    %% Plot Limits and Gray Patch on Recording Band
    xlim([0,60])
    ax = gca;
    x = [band(i)-2.5 band(i)+2.5 band(i)+2.5 band(i)-2.5];
    y = [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)];
    patch(x,y,[.8 .8 .8],'EdgeColor','none')
    set(gca,'children',flipud(get(gca,'children')))
    ylabel('Power (dB)');
    if i==1
        ylim([-9 40]);
    end
    if i==2
        ylim([-15 10]);
    end

end
%t.Padding = 'Compact';
%t.TileSpacing = 'tight';

