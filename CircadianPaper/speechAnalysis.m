close all
loaddir = '/Users/nabeeldiab/Library/Mobile Documents/com~apple~CloudDocs/Documents/Sheth/Hyper-Pursuit/DATA/speech/';
Fs = 48000;
%colors
c_red = [255,0,0]/255;
c_blue = [0,0,255]/255;
c_purple = [127,63,152]/255;
c_yellow = [255,215,0]/255;
c_white = [255,255,255]/255;
patient_labels = {'P005','P006'};
titles = {'Optimal Contact','Non-Optimal Contact'};
%% Loop Through Both Pts
for p = 1:2
    figure;
    tiles = tiledlayout(1,2);
    if p == 1
        c = c_blue;
    else
        c = c_purple;
    end
    %% Loop Through Videos/Audios
    for m = 1:2
        textg = uigetfile([loaddir,'*.TextGrid']);
        textg = fullfile(loaddir,textg);
        text = tgRead(textg);
        wfile = strcat(extractBefore(textg,'.TextGrid'),'.wav');
        wav = audioread(wfile);
        b=text.tier{1};

        %%
        try
            keep=~cellfun(@isempty,b.Label);
            rm=~cellfun(@isempty,strfind(b.Label,'*'));
            tOn=b.T1(keep&~rm);
            tOff=b.T2(keep&~rm);
            t=(tOn+tOff)/2;
            w=2;
            edges=0:w:max(tOn)+w;
            [n,edges]=histcounts(tOn,edges);
            n=n/w;
            wAmp=zeros(1,length(t));
            tW=(1:length(wav))/Fs;
            for i=1:length(t)
                wAmp(i)=rms(wav(tW>tOn(i)&tW<tOff(i)));
            end
        catch
            t = [];
            n = [];
            edges = [];
            wAmp =[];
            tW=(1:length(wav))/Fs;
            w = [];
        end
        %%
        h(m) = nexttile(m);
        yyaxis left
        plot(tW,wav*1.5+4,'Color',c);
        hold on
        bar(edges((1:end-1))+w/2,n,'FaceColor',c,'FaceAlpha',.6);
        if p == 1 && m == 2
            title({titles{1}});
        else
            title(titles{2});
        end
        ylabel('Words/s (Hz)');
        ylim([-inf,5]);
        hold on
        yyaxis right
        ts_words_per_second = edges((1:end-1))+w/2;
        words_per_second = n;
        yy = smooth(t,wAmp,0.05,'rloess');
        scatter(t,wAmp,[],'k','filled');
        ylh = ylabel('Word Volume');
        set(ylh,'rotation',-90,'VerticalAlignment','bottom');
        ylim([-.03,.08]);
        yticks(0:.02:.08);
        xlim([min(tW),max(tW)]);
        xlabel('Seconds');
        ax = gca;
        ax.YAxis(1).Color = c;
        ax.YAxis(2).Color = 'k';

    end
    r31=h(1).YAxis(1);
    r41=h(2).YAxis(1);
    r32=h(1).YAxis(2);
    r42=h(2).YAxis(2);
    linkprop([r41 r31],'Limits')
    linkprop([r42 r32],'Limits')
    title(tiles,strcat(patient_labels{p},' Response to DBS Activation'));
end
