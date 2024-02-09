%% Imports data from python into the percept_data MATLAB structure

function percept_data = python_import(python_data,percept_data)

field_list = fieldnames(python_data);

for i = 1:length(field_list)
    python_data.(field_list{i}) = struct(python_data.(field_list{i}));
    field_list2 = fieldnames(python_data.(field_list{i}));
    for j = 1:length(field_list2)
        if contains(field_list2{j},'Raw') %Import raw data as matrix
            python_data.(field_list{i}).(field_list2{j}) = double(python_data.(field_list{i}).(field_list2{j}).values);
        elseif contains(field_list2{j},'State') %Import state matrix table as numeric table with subject in first column
            pt_names = string(python_data.(field_list{i}).(field_list2{j}).index.tolist)';
            column_names = string(python_data.(field_list{i}).(field_list2{j}).columns.tolist);
            temp_table = double(python_data.(field_list{i}).(field_list2{j}).values);
            python_data.(field_list{i}).(field_list2{j}) = [array2table(pt_names,"VariableNames","Subject"),array2table(temp_table,"VariableNames",column_names)];
        elseif contains(field_list2{j},'CI') %Import confidence intervals as table of strings
            temp_table = [];
            pt_names = string(python_data.(field_list{i}).(field_list2{j}).index.tolist)';
            column_names = ["Subject",string(python_data.(field_list{i}).(field_list2{j}).columns.tolist)];
            temp_cell = cell(python_data.(field_list{i}).(field_list2{j}).values.tolist)';
            for n = 1:length(temp_cell)
                temp_table(n,:) = string(temp_cell{n});
            end
            temp_table = [pt_names,temp_table];
            python_data.(field_list{i}).(field_list2{j}) = array2table(temp_table,"VariableNames",column_names);
        else %Import all other as table of numbers
            column_names = string(python_data.(field_list{i}).(field_list2{j}).columns.tolist);
            temp_table = double(python_data.(field_list{i}).(field_list2{j}).values);
            python_data.(field_list{i}).(field_list2{j}) = array2table(temp_table,"VariableNames",column_names);
        end
    end
end

matlab_data.cosinor{1} = struct(python_data.Cosinor1);
matlab_data.cosinor{2} = struct(python_data.Cosinor2);
matlab_data.linAR{1} = struct(python_data.LinAR1);
matlab_data.linAR{2} = struct(python_data.LinAR2);
matlab_data.SE{1} = struct(python_data.SE1);
matlab_data.SE{2} = struct(python_data.SE2);

try
    matlab_data.NN_AR{1} = struct(python_data.NN_AR1);
    matlab_data.NN_AR{2} = struct(python_data.NN_AR2);
end


%% Metric-Generated Raw Data

percept_data.cosinor_matrix(:,1) = percept_data.days(:,1);
percept_data.linearAR_matrix(:,1) = percept_data.days(:,1);
percept_data.nonlinearAR_matrix(:,1) = percept_data.days(:,1);

for hemisphere = 1:2
    for j = 1:size(percept_data.days,1)
        subject = percept_data.days{j,1};       
        try %Cosinor
            percept_data.cosinor_matrix{j,hemisphere+1} = matlab_data.cosinor{hemisphere}.(['Cosinor_' subject '_Raw']);
        end
        try %Linear AR
            percept_data.linearAR_matrix{j,hemisphere+1} = matlab_data.linAR{hemisphere}.(['LinAR_' subject '_Raw']);
        end
        try %Nonlinear AR
            percept_data.nonlinearAR_matrix{j,hemisphere+1} = matlab_data.NN_AR{hemisphere}.(['NN_AR' subject '_Raw']);
        end
    end
end

%% Metric R2 values

percept_data.cosinor_R2(:,1) = percept_data.days(:,1);
percept_data.linearAR_R2(:,1) = percept_data.days(:,1);
percept_data.nonlinearAR_R2(:,1) = percept_data.days(:,1);

for hemisphere = 1:2
    for j = 1:size(percept_data.days,1)
        subject = percept_data.days{j,1};       
        try %Cosinor
            temp_data = nan(1,length(percept_data.days{j,hemisphere+1}));
            [~,day_idx] = intersect(percept_data.days{j,hemisphere+1},matlab_data.cosinor{hemisphere}.(['Cosinor_' subject '_Metric']).Day');
            temp_data(day_idx) = matlab_data.cosinor{hemisphere}.(['Cosinor_' subject '_Metric']).R2;
            percept_data.cosinor_R2{j,hemisphere+1} = temp_data;
        end
        try %Linear AR
            temp_data = nan(1,length(percept_data.days{j,hemisphere+1}));
            [~,day_idx] = intersect(percept_data.days{j,hemisphere+1},matlab_data.linAR{hemisphere}.(['LinAR_' subject '_Metric']).Day');
            temp_data(day_idx) = matlab_data.linAR{hemisphere}.(['LinAR_' subject '_Metric']).R2;
            percept_data.linearAR_R2{j,hemisphere+1} = temp_data;        end
        try %Nonlinear AR
            temp_data = nan(1,length(percept_data.days{j,hemisphere+1}));
            [~,day_idx] = intersect(percept_data.days{j,hemisphere+1},matlab_data.NN_AR{hemisphere}.(['NN_AR_' subject '_Metric']).Day');
            temp_data(day_idx) = matlab_data.NN_AR{hemisphere}.(['NN_AR_' subject '_Metric']).R2;
            percept_data.nonlinearAR_R2{j,hemisphere+1} = temp_data;        end
    end
end

%% ROC

percept_data.ROC.cosinor(:,1) = {'Norm','Delta'};

for hemisphere = 1:2
    %Cosinor
    percept_data.ROC.cosinor{1,hemisphere+1} = matlab_data.cosinor{hemisphere}.Cosinor_Norm_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC.cosinor{2,hemisphere+1} = matlab_data.cosinor{hemisphere}.Cosinor_Delta_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC_metrics.cosinor{1,hemisphere+1} = matlab_data.cosinor{hemisphere}.Cosinor_Norm_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.cosinor{2,hemisphere+1} = matlab_data.cosinor{hemisphere}.Cosinor_Delta_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.cosinor(:,1) = {'Daily Model','Delta Model'};

    %Linear AR
    percept_data.ROC.linearAR{1,hemisphere+1} = matlab_data.linAR{hemisphere}.LinAR_Norm_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC.linearAR{2,hemisphere+1} = matlab_data.linAR{hemisphere}.LinAR_Delta_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC_metrics.linearAR{1,hemisphere+1} = matlab_data.linAR{hemisphere}.LinAR_Norm_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.linearAR{2,hemisphere+1} = matlab_data.linAR{hemisphere}.LinAR_Delta_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.linearAR(:,1) = {'Daily Model','Delta Model'};

    %Sample Entropy
    percept_data.ROC.entropy{1,hemisphere+1} = matlab_data.SE{hemisphere}.SE_Norm_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC.entropy{2,hemisphere+1} = matlab_data.SE{hemisphere}.SE_Delta_ROC_AUC_Predictions(:,1:2);
    percept_data.ROC_metrics.entropy{1,hemisphere+1} = matlab_data.SE{hemisphere}.SE_Norm_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.entropy{2,hemisphere+1} = matlab_data.SE{hemisphere}.SE_Delta_ROC_AUC_Performance_Statistics;
    percept_data.ROC_metrics.entropy(:,1) = {'Daily Model','Delta Model'};

    %Nonlinear AR
    try
        percept_data.ROC.nonlinearAR{1,hemisphere+1} = matlab_data.NN_AR{hemisphere}.NN_AR_Norm_ROC_AUC_Predictions(:,1:2);
        percept_data.ROC.nonlinearAR{2,hemisphere+1} = matlab_data.NN_AR{hemisphere}.NN_AR_Delta_ROC_AUC_Predictions(:,1:2);
        percept_data.ROC_metrics.nonlinearAR{1,hemisphere+1} = matlab_data.NN_AR{hemisphere}.NN_AR_Norm_ROC_AUC_Performance_Statistics;
        percept_data.ROC_metrics.nonlinearAR{2,hemisphere+1} = matlab_data.NN_AR{hemisphere}.NN_AR_Delta_ROC_AUC_Performance_Statistics;
        percept_data.ROC_metrics.nonlinearAR(:,1) = {'Daily Model','Delta Model'};
    end
end
%% KFold States

for hemisphere = 1:2
    %Cosinor
    percept_data.kfold.cosinor{1,hemisphere} = matlab_data.cosinor{hemisphere}.Cosinor_State_Metrics;
    percept_data.kfold_CI.cosinor{1,hemisphere} = matlab_data.cosinor{hemisphere}.Cosinor_CI;
    
    %Linear AR
    percept_data.kfold.linearAR{1,hemisphere} = matlab_data.linAR{hemisphere}.LinAR_State_Metrics;
    percept_data.kfold_CI.linearAR{1,hemisphere} = matlab_data.linAR{hemisphere}.LinAR_CI;
    
    %Sample Entropy
    percept_data.kfold.entropy{1,hemisphere} = matlab_data.SE{hemisphere}.SE_State_Metrics;
    percept_data.kfold_CI.entropy{1,hemisphere} = matlab_data.SE{hemisphere}.SE_CI;
    
    %Nonlinear AR
    try
        percept_data.kfold.nonlinearAR{1,hemisphere} = matlab_data.NN_AR{hemisphere}.NN_State_Metrics;
        percept_data.kfold_CI.nonlinearAR{1,hemisphere} = matlab_data.NN_AR{hemisphere}.NN_CI;
    end
end

end