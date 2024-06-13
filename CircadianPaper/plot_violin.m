function plot_violin(percept_data,hemisphere,zone_index,patient_list,models)

% Plot all available models if user inputs "all"
if ~exist('models','var') || strcmp(lower(models),'all') || ~iscell(models) || isempty(models)
    if isfield(percept_data,'nonlinearAR_R2') %List of models to analyze
        models = {'Cosinor','LinearAR','NonlinearAR','Entropy'};
    else
        models = {'Cosinor','LinearAR','Entropy'};
    end
end

% Save a temporary mat file to pass to python
mat_file_path = [fileparts(fileparts(matlab.desktop.editor.getActiveFilename)) '\Demo\temp.mat'];
save(mat_file_path,'percept_data','zone_index')

pyrunfile("violin_plot.py","saveDict",hemi=py.int(hemisphere-1),mat_file=mat_file_path,pt=py.list(patient_list),models=py.list(models));

end