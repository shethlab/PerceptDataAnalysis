%% Imports data from python into the percept_data MATLAB structure

function percept_data = python_import_ROC(python_data,percept_data,models,permut_testing)

model_field = replace(models,{'Cosinor','LinAR'},{'cosinor','linAR'}); % Secondary list of model names to match fieldnames in python struct

field_list = fieldnames(python_data);

for i = 1:length(field_list)
    python_data.(field_list{i}) = struct(python_data.(field_list{i}));
    field_list2 = fieldnames(python_data.(field_list{i}));
    for j = 1:length(field_list2)
            column_names = string(python_data.(field_list{i}).(field_list2{j}).columns.tolist);
            temp_table = double(python_data.(field_list{i}).(field_list2{j}).values);
            python_data.(field_list{i}).(field_list2{j}) = array2table(temp_table,"VariableNames",column_names);
    end
end

matlab_data.cosinor{1} = struct(python_data.Cosinor1);
matlab_data.cosinor{2} = struct(python_data.Cosinor2);
matlab_data.linAR{1} = struct(python_data.LinAR1);
matlab_data.linAR{2} = struct(python_data.LinAR2);
try
    matlab_data.NN_AR{1} = struct(python_data.NN_AR1);
    matlab_data.NN_AR{2} = struct(python_data.NN_AR2);
end
matlab_data.SE{1} = struct(python_data.SE1);
matlab_data.SE{2} = struct(python_data.SE2);

%% ROC Predictions

for hemisphere = 1:2
    for m = 1:length(models)
        percept_data.ROC.(model_field{m})(:,1) = {'Norm','Delta'};
        percept_data.ROC.(model_field{m}){1,hemisphere+1} = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Predictions'])(:,1:2);
        percept_data.ROC.(model_field{m}){2,hemisphere+1} = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Predictions'])(:,1:2);
    end
end

%% Leave-one-patient-out Logistic Regression Metrics

if permut_testing %Skip if no leave-one-out permutation testing was performed
    percept_data.Regression_metrics.AUROC(1:2,1) = {'Delta','Daily'};
    percept_data.Regression_metrics.Balanced_Accuracy(1:2,1) = {'Delta','Daily'};
    
    for hemisphere = 1:2
        for m = 1:length(models)
            %AUROC Delta Stats
            percept_data.Regression_metrics.AUROC{1,hemisphere+1}(1,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Performance_Statistics']).ROC_AUC; % AUROC
            percept_data.Regression_metrics.AUROC{1,hemisphere+1}(2,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Randomization_Statistics']).Chance_AUC; % AUROC with randomized labels
            percept_data.Regression_metrics.AUROC{1,hemisphere+1}(3,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Randomization_Statistics']).AUC_Pvalue; % P-value for AUROC with randomized labels
            percept_data.Regression_metrics.AUROC{1,hemisphere+1}(4,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Circular_Shift_Statistics']).AUC_Pvalue; % P-value for AUROC with circularly-shifted labels
            
            %AUROC Daily Stats
            percept_data.Regression_metrics.AUROC{2,hemisphere+1}(1,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Performance_Statistics']).ROC_AUC; % AUROC
            percept_data.Regression_metrics.AUROC{2,hemisphere+1}(2,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Randomization_Statistics']).Chance_AUC; % AUROC with randomized labels
            percept_data.Regression_metrics.AUROC{2,hemisphere+1}(3,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Randomization_Statistics']).AUC_Pvalue; % P-value for AUROC with randomized labels
            percept_data.Regression_metrics.AUROC{2,hemisphere+1}(4,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Circular_Shift_Statistics']).AUC_Pvalue; % P-value for AUROC with circularly-shifted labels
            
            %Balanced Accuracy Delta Stats
            percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1}(1,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Performance_Statistics']).Balanced_Accuracy; % AUROC
            percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1}(2,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Randomization_Statistics']).Chance_Balanced_Accuracy; % AUROC with randomized labels
            percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1}(3,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Randomization_Statistics']).Balanced_Accuracy_PValue; % P-value for AUROC with randomized labels
            percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1}(4,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Delta_ROC_AUC_Circular_Shift_Statistics']).Balanced_Accuracy_PValue; % P-value for AUROC with circularly-shifted labels
            
            %Balanced Accuracy Daily Stats
            percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1}(1,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Performance_Statistics']).Balanced_Accuracy; % AUROC
            percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1}(2,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Randomization_Statistics']).Chance_Balanced_Accuracy; % AUROC with randomized labels
            percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1}(3,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Randomization_Statistics']).Balanced_Accuracy_PValue; % P-value for AUROC with randomized labels
            percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1}(4,m) = matlab_data.(model_field{m}){hemisphere}.([models{m},'_Norm_ROC_AUC_Circular_Shift_Statistics']).Balanced_Accuracy_PValue; % P-value for AUROC with circularly-shifted labels
        end
    
        % Convert statistics matrices into tables
        percept_data.Regression_metrics.AUROC{1,hemisphere+1} = array2table(percept_data.Regression_metrics.AUROC{1,hemisphere+1},'RowNames',{'True Label','Shuffled Label','P-Val (Random)','P-Val (Circular)'},'VariableNames',models);
        percept_data.Regression_metrics.AUROC{2,hemisphere+1} = array2table(percept_data.Regression_metrics.AUROC{2,hemisphere+1},'RowNames',{'True Label','Shuffled Label','P-Val (Random)','P-Val (Circular)'},'VariableNames',models);
        percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1} = array2table(percept_data.Regression_metrics.Balanced_Accuracy{1,hemisphere+1},'RowNames',{'True Label','Shuffled Label','P-Val (Random)','P-Val (Circular)'},'VariableNames',models);
        percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1} = array2table(percept_data.Regression_metrics.Balanced_Accuracy{2,hemisphere+1},'RowNames',{'True Label','Shuffled Label','P-Val (Random)','P-Val (Circular)'},'VariableNames',models);
    end
end

end