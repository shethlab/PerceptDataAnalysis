%% Imports data from python into the percept_data MATLAB structure

function percept_data = python_import_R2(python_data,percept_data,models)

model_field = replace(models,{'Cosinor','LinAR'},{'cosinor','linAR'}); % Secondary list of model names to match fieldnames in python struct

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
try
    matlab_data.NN_AR{1} = struct(python_data.NN_AR1);
    matlab_data.NN_AR{2} = struct(python_data.NN_AR2);
end
matlab_data.SE{1} = struct(python_data.SE1);
matlab_data.SE{2} = struct(python_data.SE2);

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

%% KFold States

for hemisphere = 1:2
    for m = 1:length(models)
        percept_data.kfold.(model_field{m}){1,hemisphere} = matlab_data.(model_field{m}){hemisphere}.([models{m},'_State_Metrics']);
        percept_data.kfold_CI.(model_field{m}){1,hemisphere} = matlab_data.(model_field{m}){hemisphere}.([models{m},'_CI']);
    end
end

end