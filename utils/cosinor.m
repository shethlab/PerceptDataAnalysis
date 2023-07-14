function [amplitude,acrophase,p_value,fit_model] = cosinor(t,y,w,num_components,num_peaks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COSINOR 	[]=cosinor(t,y,w,alpha)
%
% Input:
%   t - time series
%   y - value of series at time t
%   w - cycle length, defined by user based on prior knowledge of time
%       series
%   alpha
%
% Define Variables:
%   M - Mesor, the average cylce value
%   Amp - Amplitude, half the distance between peaks of the fitted
%       waveform
%   phi - Acrophase, time point in the cycle of highest amplitude (in
%       radians)
%   RSS - Residual Sum of Squares, a measure of the deviation of the
%       cosinor fit from the original waveform

if nargin ~= 5
    error('Incorrect number of inputs.');
elseif length(t) < 4
    error('There must be atleast four time measurements.')
end

%Transpose data into columns
if size(t,1)==1
    t=t';
end
if size(y,1)==1
    y=y';
end

w=w/24; %convert period from hours to days

%Generate sinuosoidal component inputs for regression model
X_fit=[];
for i=1:num_components
    A=sin(t/(w/i)*2*pi);
    B=cos(t/(w/i)*2*pi);
    X_fit=[X_fit,A,B];
end

%Fit the linear regression model to the sinusoidal inputs
fit_model=fitlm(X_fit,y);

%Calculation of miscellaneous measures
f=fit_model.Fitted; %Raw data points of sinuosidal fit model
mesor=median([min(f),max(f)]); %MESOR is defined as the cycle median
p_value=fit_model.ModelFitVsNullModel.Pvalue; %P value of model fit vs constant model

%Acrophase and amplitude calculation
[peaks,peak_locs]=findpeaks(f,t,'MinPeakHeight',mesor,'MinPeakDistance',1/24);
disc_peaks=discretize(mod(peak_locs,1),num_peaks);
disc_acro=unique(disc_peaks);

if length(disc_acro) > 1 %Multiple peaks per cycle
    for i=1:num_peaks
        acrophase(i)=median(mod(peak_locs(disc_peaks==disc_acro(end-i+1)),1)*2*pi); %outputting as radians
        amplitude(i)=(median(peaks(disc_peaks==disc_acro(end-i+1)))-min(f))/2;
    end
elseif isempty(disc_acro) %No peaks identified
    acrophase=nan;
    amplitude=nan;
else %Single peak per cycle
    acrophase=mod(peak_locs(end),1)*2*pi; %outputting as radians
    amplitude=(peaks(end)-min(f))/2;
end

%% Plot cosinor vs original data (optional)

% plot(t,y,'Color',[0.6,0.6,0.6]); hold on;
%     xlabel('Days Since DBS On');
%     ylabel('LFP Amplitude (uVp)');
% plot(t,f,'r');
%     legend('Original', 'Cosinor');
%     xlim([min(t) max(t)]);
% set(gcf,'Position',[0,0,750,500])
% title([num2str(num_components),'-Component'])
% hold off;