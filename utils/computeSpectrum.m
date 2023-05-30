%% Offline Computation of Medtronic Power Spectrum using Raw Time Domain Input

% Input 30 second (7500 Sample) stream of LFP data (raw)

function [LFPamplitude,frequency] = computeSpectrum(raw)

%% Convert Average Voltage to Peak Voltage
working = raw*pi/2;
fs = 250;

%% Compute the Spectrum at the frequencies using a 256 point offline FFT (at fs = 250, this gives roughly 1Hz bin sizes)
[psd,frequency] = pwelch(working,fs,fs*0.6,256,fs);

%% Return the Square root of spectrum for LFP amplitude
LFPamplitude = psd.^0.5;
end
