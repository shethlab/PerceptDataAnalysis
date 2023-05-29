%%
load("streamsplot.mat")
addpath(genpath('C:\Users\Nicole\OneDrive\Documents\GitHub\PerceptDataAnalysis\'))
colors = {'r','b'};
band=[8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79,8.79];
%streams = {stream1,stream2,stream4,stream5,stream6,stream7,stream8};
pats = {'001','002','004','005','006','007','008'};
figure('Renderer', 'painters', 'PaperUnits','centimeters','PaperPosition',[0,0,8.7,8.85]);
for i = 1:length(streams)
    pt = streams{i};
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
        else
            s=i;
        end
        ax = subplot(3,3,s)
        plot(freq,20*log10(amp),'Color',colors{j});
        hold on 
        xline(band(i))
       
    end
        
%     if or(or(i==7,i==6),i==4)
%     xlabel('Frequency (Hz)')
%     end
%     if or(or(i==1,i==4),i==7)
%     ylabel('Power (dB)')
%     end
    box off
%     if isempty(pt{1})
%         legend({'Right Hemisphere'});
%     elseif isempty(pt{2})
%         legend({'Left Hemisphere'});
%     else
%         legend({'Left Hemisphere','Right Hemisphere'});
%     end

    %title(strcat("P",pats{i}))
    %axis square
    
    xlim([0,60])
    x = [band(i)-2.5 band(i)+2.5 band(i)+2.5 band(i)-2.5];
        y = [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)];
        patch(x,y,[.8 .8 .8],'EdgeColor','none')
        set(gca,'children',flipud(get(gca,'children')))

end
%t.Padding = 'tight';

saveas(gcf,'PSDs.png')
saveas(gcf,'PSDs.svg')

