%% Extracts percept LFP trend (chronic LFP) values given a json input.

function LFP_trend=extract(filename)
    % Extract json
    js = jsondecode(fileread(filename));
    
    % Display time of session and location of DBS lead to user
    sessionDate=datetime(js.SessionDate,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''');
    leadLocation=extractAfter(js.LeadConfiguration.Final(1).LeadLocation,'.');
    disp(string(sessionDate) + ' - ' + leadLocation)
    
    if isfield(js.DiagnosticData,'LFPTrendLogs')
        % Initialize data-holding variables
        data=js.DiagnosticData.LFPTrendLogs;
        data_left=struct('DateTime',{},'LFP',{},'AmplitudeInMilliAmps',{});
        data_right=struct('DateTime',{},'LFP',{},'AmplitudeInMilliAmps',{});
        
        % Concatenate left hemisphere data
        if isfield(data,'HemisphereLocationDef_Left') 
            fields = fieldnames(data.HemisphereLocationDef_Left);          
            for i=1:length(fields)
                data_left=[data_left;data.HemisphereLocationDef_Left.(fields{i})];
            end
        end
    
        % Concatenate right hemisphere data
        if isfield(data,'HemisphereLocationDef_Right') 
            fields = fieldnames(data.HemisphereLocationDef_Right);          
            for i=1:length(fields)
                data_right=[data_right;data.HemisphereLocationDef_Right.(fields{i})];
            end
        end
           
        % Generate ascending list of unique datetimes
        date_time=sort(unique([{data_left.DateTime},{data_right.DateTime}]))';
       
        % Create 2 row LFP/stim matrix with values sorted to match respective datetimes above
        LFP=nan(2,max(length(data_left),length(data_right)));
        stim_amp=nan(2,max(length(data_left),length(data_right)));

        [~,left_indices]=ismember({data_left.DateTime},date_time);
        LFP(1,left_indices)=[data_left.LFP]; %left_indices=0 indicates non-member
        stim_amp(1,left_indices(left_indices>0))=[data_left.AmplitudeInMilliAmps]; %left_indices=0 indicates non-member
        
        [~,right_indices]=ismember({data_right.DateTime},date_time);
        LFP(2,right_indices(right_indices>0))=[data_right.LFP]; %right_indices=0 indicates non-member
        stim_amp(2,right_indices(right_indices>0))=[data_right.AmplitudeInMilliAmps]; %right_indices=0 indicates non-member
        
        % Export values
        date_time=datetime(date_time,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
        LFP_trend = table(date_time,LFP(1,:)',LFP(2,:)',stim_amp(1,:)',stim_amp(2,:)','VariableNames',{'Timestamp','LFP Amp Left','LFP Amp Right','Stim Amp Left','Stim Amp Right'});
    else
        LFP_trend=[];
    end
end