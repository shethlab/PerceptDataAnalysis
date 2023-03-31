%% Offline Computation of Medtronic Power Spectrum using Raw Time Domain Input

% Input 30 second (7500 Sample) stream of LFP data

function [LFPamplitude,frequency] = computeSpectrum(raw,freq_array)

%% Convert Average Voltage to Peak Voltage
working = raw*pi/2;
fs = 250;

%% Compute the Spectrum at the frequencies specified by the Medtronic Freq Vector (not a 256 point offline FFT)
[psd,frequency] = pwelch(working,fs,fs*0.6,freq_array,fs);

%% Return the Square root of spectrum for LFP amplitude
LFPamplitude = psd.^0.5;
end
