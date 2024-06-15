%% This function is used to calculate the various data metrics as described
% in Provenza, Reddy, and Allam et al. 2024. Metrics include cosinor R2,
% amplitude, and acrophase; linearAR R2; nonlinear AR R2; and sample entropy. 
% This function has six required inputs and four optional ones:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is generate_data.m, which creates the
%       appropriately-formatted data structure. This structure must contain
%       three fields called "days," "LFP_norm_matrix," and "LFP_filled_matrix."
%   2. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   3. cosinor_window_left: the number of days prior to the day of interest to
%       include in the calculation window for cosinor (e.g. a window of i-n:i 
%       where i is the day of interest).
%   4. cosinor_window_right: the number of days after the day of interest to
%       include in the calculation window for cosinor (e.g. a window of i:i+n 
%       where i is the day of interest). For example, a 1-day window (i.e. daily)
%       would need both windows set to 0, a 3-day retrospective window
%       would need window_left = 2 and window_right = 0, and a 5-day
%       centered window would need both windows set to 2.
%   5. SE_window_left: the number of days prior to the day of interest to
%       include in the calculation window for sample entropy (e.g. a window
%       of i-n:i where i is the day of interest).
%   6. SE_window_right: the number of days after the day of interest to
%       include in the calculation window for sample entropy (e.g. a window 
%       of i:i+n where i is the day of interest). For example, a 1-day window
%       (i.e. daily) would need both windows set to 0, a 3-day retrospective
%       window would need window_left = 2 and window_right = 0, and a 5-day
%       centered window would need both windows set to 2.
%   7 (optional). skip_python: a flag which, when set to 1, skips
%       additional python analyses (overrides the next two optional variables).
%       The default is 0 (runs python). This is useful for quickly updating 
%       cosinor or sample entropy values.
%   8 (optional). permut_testing: a flag which, when set to 1, performs
%       permutation testing on pooled-patient classifiers to generate a
%       chance distribution for further analysis. The default is 0 (do not
%       run).
%   9 (optional). include_nonlinear: a flag which, when set to 1, includes
%       performs calculations for the nonlinear autoregressive model. The
%       default is 0 (do not run) because the nonlinear AR is slow to run
%       and resource-intensive.
%   10 (optional). is_demo: a flag which, when set to 1, signals that the
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
%   1. percept_data: the updated data structure including all of the input
%       information, as well as the new calculated data. New fields include
%       "entropy," "amplitude," "acrophase," and "cosinor_p." If the python
%       code is also processed, additional fields include "cosinor_R2,"
%       "cosinor_matrix," "linearAR_R2," "linearAR_matrix,"
%       "nonlinearAR_R2," "nonlinearAR_matrix," "ROC," and "kfold."

function percept_data = calc_circadian(percept_data,zone_index,cosinor_window_left,cosinor_window_right,SE_window_left,SE_window_right,skip_python,permut_testing,include_nonlinear,is_demo)

%Warning if improper window size inputs
cosinor_window = [cosinor_window_left,cosinor_window_right];
if ~isnumeric(cosinor_window) || any(cosinor_window < 0) || any(mod(cosinor_window,1) ~= 0)
    error('Cosinor window inputs must be integers >= 0.')
end
SE_window = [SE_window_left,SE_window_right];
if ~isnumeric(SE_window) || any(SE_window < 0) || any(mod(SE_window,1) ~= 0)
    error('Sample entropy window inputs must be integers >= 0.')
end

%Checking if python analysis should be performed
if ~exist('skip_python','var') || ~isnumeric(skip_python) || isempty(skip_python) || skip_python ~= 1
    skip_python = 0;
    %Checking if permutation testing is to be performed
    if ~exist('permut_testing','var') || ~isnumeric(permut_testing) || isempty(permut_testing) || permut_testing ~= 1
        disp('Will not perform permutation testing.')
        permut_testing = py.bool(0);
    else
        disp('Will perform permutation testing.')
        permut_testing = py.bool(1);
    end
    
    %Checking if nonlinear AR is to be included in model list
    if ~exist('include_nonlinear','var') || ~isnumeric(include_nonlinear) || isempty(include_nonlinear) || include_nonlinear ~= 1
        disp('Models to analyze: cosinor, linear AR, sample entropy.')
        models = {'Cosinor','LinAR','SE'};
    else
        disp('Models to analyze: cosinor, linear AR, nonlinear AR, sample entropy.')
        models = {'Cosinor','LinAR','NN_AR','SE'};
    end
else
    disp('Python analysis skipped by user.')
end

% If the demo flag is enabled, uses hardcoded cosinor parameters for the demo dataset
if exist('is_demo','var') && is_demo == 1
    all_components = [3,2,1,1,1,1,2,1,2];
    all_peaks = [2,2,1,1,1,1,2,1,2];
end

pause(2)

%% Matlab calculations
for j = 1:size(percept_data.LFP_norm_matrix,1)
    if exist('is_demo','var') && is_demo == 1
        num_components = all_components(j);
        num_peaks = all_peaks(j);
    else
        num_components = input(['Enter the number of cosinor components for subject ',percept_data.days{j,1},': ']); %cosinor parameter input
        num_peaks = input(['Enter the number of cosinor peaks for subject ',percept_data.days{j,1},': ']); %cosinor parameter input
    end

    %Warning if improper cosinor inputs
    if ~isnumeric([num_components,num_peaks]) || any([num_components,num_peaks] < 1) || any(mod([num_components,num_peaks],1) ~= 0)
        error('Cosinor inputs must be positive integers.')
    else %Proceed with code and save the component to pass to python later
        all_components(j) = num_components;
    end

    for hemisphere=1:2
        %Temporary variables per iteration
        days = percept_data.days{j,hemisphere+1};
        LFP_norm = percept_data.LFP_norm_matrix{j,hemisphere+1};
        LFP_filled = percept_data.LFP_filled_matrix{j,hemisphere+1};
        time = percept_data.time_matrix{j,hemisphere+1};

        %Check that the day values line up with the data and skip if not
        if length(days) ~= size(LFP_filled,2)
            disp('Size mismatch between day values and LFP data. Skipping this hemisphere.')
            continue
        end

        %Find indices of discontiuous days of data
        start_index = find(diff(days) > 1);
        try
            start_index = [1,start_index+1,length(days)+1];
        catch
            start_index = [1,length(days)+1];
        end
        
        %Initializing metrics
        sample_entropy = nan(1,length(days));
        acro = nan(1,length(days),num_peaks);
        amp = nan(1,length(days),num_peaks);
        p = nan(1,length(days));
        
        for i = 1:length(days) %Iterating on the specified window for each day in the dataset for cosinor
            disp([percept_data.days{j,1},' - ',num2str(i)])
            if any((start_index > i-cosinor_window_left & start_index <= i+cosinor_window_right) | length(days) < i+cosinor_window_right)
                % Skipping calculations if there are full-day or greater gaps in data in the specified window
            else
                y = reshape(LFP_norm(:,i-cosinor_window_left:i+cosinor_window_right),[1,144*(sum(cosinor_window)+1)]);
                t = reshape(time(:,i-cosinor_window_left:i+cosinor_window_right),[1,144*(sum(cosinor_window)+1)]);
                
                %Calculation of cosinor amplitude, acrophase, p-value
                [amp(1,i,1:num_peaks),acro(1,i,1:num_peaks),p(i),fit] = cosinor(t,y,24,num_components,num_peaks);
            end
        end
        
        for i = 1:length(days) %Iterating on hard-coded 1-day window to generate daily acrophases for template-plotting code
            disp([percept_data.days{j,1},' - ',num2str(i)])
            if any((start_index > i & start_index <= i) | length(days) < i)
                % Skipping calculations if there are full-day or greater gaps in data in the specified window
            else
                y = reshape(LFP_norm(:,i),[1,144]);
                t = reshape(time(:,i),[1,144]);
                
                %Calculation of cosinor amplitude, acrophase, p-value
                [~,template_acro(1,i,1:num_peaks),template_p(1,i)] = cosinor(t,y,24,num_components,num_peaks);
            end
        end

        for i = 1:length(days) %Iterating on the specified window for each day in the dataset for sample entropy
            disp([percept_data.days{j,1},' - ',num2str(i)])
            if any((start_index > i-SE_window_left & start_index <= i+SE_window_right) | length(days) < i+SE_window_right)
                % Skipping calculations if there are full-day or greater gaps in data in the specified window
            else
                y_filled = reshape(LFP_filled(:,i-SE_window_left:i+SE_window_right),[1,144*(sum(SE_window)+1)]);
                
                %Calculation of sample entropy
                s = SampEn(y_filled,'m',2,'tau',1,'r',3.6,'Logx',exp(1));
                sample_entropy(i) = s(3);
            end
        end
    
    %Saving the patient/hemisphere metrics to the overall data structure    
    percept_data.entropy{j,hemisphere+1} = sample_entropy;
    percept_data.amplitude{j,hemisphere+1} = amp;
    percept_data.acrophase{j,hemisphere+1} = acro;
    percept_data.cosinor_p{j,hemisphere+1} = p;
    percept_data.template_acro{j,hemisphere+1} = template_acro;
    percept_data.template_p{j,hemisphere+1} = template_p;
    end
    
    %Copying patient labels
    percept_data.entropy{j,1} = percept_data.days{j,1};
    percept_data.amplitude{j,1} = percept_data.days{j,1};
    percept_data.acrophase{j,1} = percept_data.days{j,1};
    percept_data.cosinor_p{j,1} = percept_data.days{j,1};
    percept_data.template_acro{j,1} = percept_data.days{j,1};
    percept_data.template_p{j,1} = percept_data.days{j,1};
end

%% Carry the data to python for advanced calculations (if python not skipped)

if skip_python ~= 1
    % Save data to temp mat file in Demo folder to pass to Python
    mat_file_path = [fileparts(fileparts(matlab.desktop.editor.getActiveFilename)) '\Demo\temp.mat'];
    save(mat_file_path,'percept_data','zone_index')
    
    % Convert cosinor components into python integer array
    all_components = num2cell(all_components);
    for j = 1:length(all_components)
        all_components{j} = py.int(all_components{j});
    end
    
    % Run the python file calc_circadian_advanced (see file-specific comments for more info)
    disp('Running python calculations. This may take a while.')
    for m = 1:length(models)
        for hemisphere = 1:2
            disp(['Running - ' models{m} ' Hemisphere ' num2str(hemisphere)])
            python_data.([models{m},num2str(hemisphere)]) = pyrunfile("calc_circadian_advanced.py","saveDict",hemi=py.int(hemisphere-1),mat_file=mat_file_path,...
                components=py.list(all_components),pt_index=py.list(cellfun(@(x) py.int(x),num2cell(0:size(percept_data.LFP_filled_matrix(:,1))-1),UniformOutput=false)),...
                pt_names=py.list(percept_data.LFP_filled_matrix(:,1)'),models=py.list(models(m)),permut_testing=permut_testing);
        end
    end
    
    percept_data = python_import(python_data,percept_data,models,permut_testing); %Import data into matlab struct
    delete(mat_file_path) %Remove temp mat file
end

end