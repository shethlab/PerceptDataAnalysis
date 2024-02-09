%% This function is used to generate power spectral density (PSD) plots 
% from Percept BrainSense Surveys or BrainSense Streaming. This function 
% requires 4 inputs:
%   1. percept_data: the data structure containing the Percept data. This
%       structure must contain a field called "streams," which is an n x 3 
%       cell array (where n denotes number of patients). Each row, corresponding
%       to a patient, should consistent of the following three columns - 
%       1) subject name, 2) left hemisphere data, and 3) right hemisphere 
%       data. Data should be time-domain vectors from BrainSense streaming 
%       (length =/= 100) or the amplitude vector from the pre-calculated
%       BrainSense survey PSD (length == 100).
%   2. band: the center frequency (in Hz) of interest. This will appear as
%       black line with a shaded grey box of width +/- 2.5 Hz.
%   3. height: the number of rows of subplots
%   4. width: the number of columns of subplots
%
% The output is a height x width subplot of PSDs.

function plot_PSD(percept_data,band,height,width)

%% Detailed optional inputs
color_left = [230,145,60]/255; % Can adjust color of left hemisphere lines
color_right = [0,162,89]/255; % Can adjust color of right hemisphere lines
fig_scaling = 4; % Height & width of each subplot in cm (default 4)
PSD_upper_limit = 60; % Upper limit in hz of PSD frequencies to display

%% Setup/loading
streams = percept_data.streams;
colors = {color_left,color_right};
figure('Units','centimeters','Position',[0,0,width*fig_scaling,height*fig_scaling],'Color','w');
tiledlayout(height,width);

for j = 1:size(streams,1)
    nexttile;
    hold on

    %% Compute and Plot spectrum for each hemisphere
    for hemisphere = 2:3
        if isempty(streams{j,hemisphere})
            continue
        elseif length(streams{j,hemisphere}) == 100 % BrainSense Survey
            amp = streams{j,hemisphere};
            freq = linspace(0,96.68,100); % Frequency list from whitepaper
        else % Brainsense streaming requiring PSD calculation
            [amp,freq] = computeSpectrum(streams{j,hemisphere});
        end
        
        plot(freq(freq<PSD_upper_limit+2),20*log10(amp(freq<PSD_upper_limit+2)),'Color',colors{hemisphere-1});
    end
    
    %% Plot Limits and Gray Patch on Recording Band
    ax = gca;
    ylims = ax.YLim;
    
    % Plot patch & line at specified center frequency with 5 hz bandwidth
    xline(band) 
    patch([band-2.5,band+2.5,band+2.5,band-2.5],[-999,-999,999,999],[.8 .8 .8],'EdgeColor','none')
    
    set(gca,'children',flipud(get(gca,'children')))
    box off
    axis square
    ylabel('Power (dB)')
    title(streams{j,1})
    ax.TitleHorizontalAlignment = 'left';
    xlim([0,PSD_upper_limit])
    ylim(ylims)
end

end