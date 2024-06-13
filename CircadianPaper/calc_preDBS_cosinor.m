%% This function is used to calculate a single cosinor fit to the entire
% pre-DBS dataset to determine fit significance using an F test. This 
% function has six required inputs and four optional ones:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is calc_circadian.m, which creates the
%       appropriately-formatted data structure. This structure must contain
%       three fields called "days" and "LFP_filled_matrix."
%   2 (optional). is_demo: a flag which, when set to 1, signals that the
%       demo dataset (demo_data.mat) is being run. This skips some
%       command-line inputs for cosinor calculations which would ordinarily
%       have to be determined by the user.
%
% This function also requests inputs from the user through a command line
% prompt. It references the following two variables for each patient to be
% processed:
%   1. Cosinor components: the number of components (i.e. N in the cosinor
%       listed in the cosinor equation of the main manuscript).
%       Practically, this is the number of local maxima that appear during
%       each sinusoidal period, which can be determined visually or
%       calculated through a periodogram. Increasing the number of
%       components increases fit strength but results in overfitting if too
%       high a number is selected.
%   2. Cosinor peaks: the number of peaks for which to calculate amplitude
%       (peak height) and acrophase (time of the peak). This value must be
%       less than or equal to the number of components.
%
% This function has one output:
%   1. cosinor_fits: a data structure containing F test results for the
%       left and right hemispheres.

function cosinor_fits = calc_preDBS_cosinor(percept_data,is_demo)

% If the demo flag is enabled, uses hardcoded cosinor parameters for the demo dataset
if exist('is_demo','var') && is_demo == 1
    all_components = [3,2,1,1,1,1,2,1,2];
    all_peaks = [2,2,1,1,1,1,2,1,2];
end

num_subjects = size(percept_data.LFP_filled_matrix,1);
cosinor_fit_left = table(percept_data.LFP_filled_matrix(:,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),'VariableNames',{'Subject','R2','p','F','df','n','Components'});
cosinor_fit_right = table(percept_data.LFP_filled_matrix(:,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),nan(num_subjects,1),'VariableNames',{'Subject','R2','p','F','df','n','Components'});

for j = 1:size(percept_data.LFP_filled_matrix,1)
    if exist('is_demo','var') && is_demo == 1
        num_components = all_components(j);
        num_peaks = all_peaks(j);
    else
        num_components = input(['Enter the number of cosinor components for subject ',percept_data.LFP_filled_matrix{j,1},': ']); %cosinor parameter input
        num_peaks = input(['Enter the number of cosinor peaks for subject ',percept_data.LFP_filled_matrix{j,1},': ']); %cosinor parameter input
    end

    %Warning if improper cosinor inputs
    if ~isnumeric([num_components,num_peaks]) || any([num_components,num_peaks] < 1) || any(mod([num_components,num_peaks],1) ~= 0)
        error('Cosinor inputs must be positive integers.')
    else %Proceed with code and save the component to pass to python later
        all_components(j) = num_components;
    end

    % Left hemisphere
    try
        % Filter all timepoints less than zero
        t = percept_data.time_matrix{j,2};
        LFP = percept_data.LFP_filled_matrix{j,2};
        t = t(t<0);
        LFP = LFP(t<0);
        
        % Fitting single cosinor to entire pre-DBS zone
        [~,~,cosinor_fit_left.p(j),fit] = cosinor(t,LFP,24,num_components,num_peaks);
        cosinor_fit_left.R2(j) = fit.Rsquared.Ordinary;
        cosinor_fit_left.F(j) = fit.ModelFitVsNullModel.Fstat;
        cosinor_fit_left.df(j) = fit.DFE;
        cosinor_fit_left.n(j) = fit.NumObservations;
        cosinor_fit_left.Components(j) = all_components(j);
    end
    
    % Right hemisphere   
    try
        % Filter all timepoints less than zero
        t = percept_data.time_matrix{j,3};
        LFP = percept_data.LFP_filled_matrix{j,3};
        t = t(t<0);
        LFP = LFP(t<0);
        
        % Fitting single cosinor to entire pre-DBS zone
        [~,~,cosinor_fit_right.p(j),fit] = cosinor(t,LFP,24,num_components,num_peaks);
        cosinor_fit_right.R2(j) = fit.Rsquared.Ordinary;
        cosinor_fit_right.F(j) = fit.ModelFitVsNullModel.Fstat;
        cosinor_fit_right.df(j) = fit.DFE;
        cosinor_fit_right.n(j) = fit.NumObservations;
        cosinor_fit_right.Components(j) = all_components(j);
    end
end

cosinor_fits{1} = cosinor_fit_left;
cosinor_fits{2} = cosinor_fit_right;

end