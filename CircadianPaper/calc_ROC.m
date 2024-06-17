%% This function is used to calculate the various data metrics as described
% in Provenza, Reddy, and Allam et al. 2024. Metrics include cosinor R2,
% amplitude, and acrophase; linearAR R2; nonlinear AR R2; and sample entropy. 
% This function has two required inputs and one optional one:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is generate_data.m, which creates the
%       appropriately-formatted data structure. This structure must contain
%       three fields called "days," "LFP_norm_matrix," and "LFP_filled_matrix."
%   2. zone_index: the structure containing the list of days in which
%       patients are behaviorally-noted as being in clinical response, non-
%       response, or hypomania. This structure is generated as part of the
%       generate_data function.
%   3 (optional). permut_testing: a flag which, when set to 1, performs
%       permutation testing on pooled-patient classifiers to generate a
%       chance distribution for further analysis. The default is 0 (do not
%       run).
%
% This function has one output:
%   1. percept_data: the updated data structure including all of the input
%       information, as well as the new calculated data. New fields include
%       "ROC," and "kfold."

function percept_data = calc_ROC(percept_data,zone_index,permut_testing)

%% Carry the data to python for advanced calculations (if python not skipped)

%Checking if permutation testing is to be performed
if ~exist('permut_testing','var') || ~isnumeric(permut_testing) || isempty(permut_testing) || permut_testing ~= 1
    disp('Will not perform permutation testing.')
    permut_testing = py.bool(0);
else
    disp('Will perform permutation testing.')
    permut_testing = py.bool(1);
end

if isfield(percept_data,'nonlinearAR_R2') %List of models to analyze
    disp('Models to analyze: cosinor, linear AR, nonlinear AR, sample entropy.')
    models = {'Cosinor','LinAR','NN_AR','SE'};
    include_NN = py.bool(1);
else
    disp('Models to analyze: cosinor, linear AR, sample entropy.')
    models = {'Cosinor','LinAR','SE'};
    include_NN = py.bool(0);
end

% Save data to temp mat file in Demo folder to pass to Python
mat_file_path = [fileparts(fileparts(matlab.desktop.editor.getActiveFilename)) '\Demo\temp_ROC.mat'];
save(mat_file_path,'percept_data','zone_index')

% Run the python file calc_circadian_advanced (see file-specific comments for more info)
disp('Running python calculations. This may take a while.')
for m = 1:length(models)
    for hemisphere = 1:2
        disp(['Running - ' models{m} ' Hemisphere ' num2str(hemisphere)])
        python_data.([models{m},num2str(hemisphere)]) = pyrunfile("calc_ROC.py","saveDict",hemi=py.int(hemisphere-1),mat_file=mat_file_path,...
            pt_id=py.list(cellfun(@(x) py.int(x),num2cell(0:size(percept_data.days(:,1))-1),UniformOutput=false)),...
            pt_name=py.list(percept_data.days(:,1)'),models=py.list(models(m)),include_NN=include_NN,permut_testing=permut_testing);
    end
end

percept_data = python_import_ROC(python_data,percept_data,models,permut_testing); %Import data into matlab struct
delete(mat_file_path) %Remove temp mat file

end