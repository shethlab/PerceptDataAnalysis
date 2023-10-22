function percept_data = generate_data(subject_name,percept_data,time_zone)
    
%% Choosing files and DBS onset date

[fileName,path] = uigetfile('*.json','MultiSelect','on','Select patient JSON files');
fileList = fullfile(path,fileName);

%Set default time zone as Central Time US if not specified
if ~exist('time_zone','var') || isempty('time_zone')
    time_zone = 'America/Chicago';
end

DBS_onset = input('Input the date of DBS onset in the format dd-MMM-yyyy (e.g 01-Jan-2000): ','s');
DBS_onset = datetime(DBS_onset,'InputFormat','dd-MMM-yyyy','TimeZone',time_zone);

%% Raw data, normalized data, and timestamps

%Initialize raw data table either as new or existing
if ~exist('percept_data','var') || isempty('percept_data') || ~any(strcmp(subject_name,percept_data.raw_data(:,1)))
    raw_data = [];
else
    raw_data = percept_data.raw_data{strcmp(subject_name,percept_data.raw_data(:,1)),2};
end

%Handling when only one file is selected
if ischar(fileList)
    fileName = {fileName};
    fileList = {fileList};
end

%Import and concatenate data from JSONs
for i = 1:length(fileList)
    raw = extract(fileList{i});
    if ~isempty(raw)
        raw_data = [raw_data; raw];
    end
end  

raw_data.Timestamp.TimeZone = time_zone;

%Remove duplicate data points
[unique_dates,unique_index,~] = unique(raw_data.Timestamp);
raw_data = raw_data(unique_index,:);
raw_data.Timestamp = unique_dates;

%Discretize data timepoints into 10 minute time-of-day (TOD) bins without date
time_hist = minutes(0:10:25*60); %generate 10 minute bins b/w 0:00 to 25:00 (daylight savings shows up as >24 hr)
disc_TOD = discretize(timeofday(unique_dates),time_hist);
disc_TOD(disc_TOD>24*6) = disc_TOD(disc_TOD>24*6)-24*6; %Shift daylight savings TOD by 24 hours to make it <24 hr

%Discretize data timepoints into dates without times
rounded_dates = dateshift(unique_dates,'start','day');
unique_rounded_dates = unique(rounded_dates);

%Reshape raw data into a 2D matrix with rows=TOD and columns=date
LFP_matrix{1} = nan(24*6,length(unique_rounded_dates));
LFP_matrix{2} = nan(24*6,length(unique_rounded_dates));

stim_matrix{1} = nan(24*6,length(unique_rounded_dates));
stim_matrix{2} = nan(24*6,length(unique_rounded_dates));

for i = 1:length(unique_rounded_dates)
    [~,idx] = ismember(rounded_dates,unique_rounded_dates(i));
    LFP_matrix{1}(disc_TOD(idx>0),i) = raw_data.('LFP Amp Left')(idx>0);
    time_matrix{1}(disc_TOD(idx>0),i) = unique_dates(idx>0);
    stim_matrix{1}(disc_TOD(idx>0),i) = raw_data.('Stim Amp Left')(idx>0);

    LFP_matrix{2}(disc_TOD(idx>0),i) = raw_data.('LFP Amp Right')(idx>0);
    time_matrix{2}(disc_TOD(idx>0),i) = unique_dates(idx>0);
    stim_matrix{2}(disc_TOD(idx>0),i) = raw_data.('Stim Amp Right')(idx>0);
end

%Generate per-hemisphere data cells 
for hemisphere = 1:2
    %Find days with no data to remove
    all_nan_days = all(isnan(LFP_matrix{hemisphere}));
    
    %List of dates containing data relative to DBS onset
    unique_cal_days = unique_rounded_dates(~all_nan_days);
    DBS_time{hemisphere} = round(days(unique_cal_days-DBS_onset));
    time_matrix{hemisphere} = days(time_matrix{hemisphere}-DBS_onset);

    %Remove empty days from LFP data matrix and create nan-filled, outlier-removed, per-day normalized matrix
    LFP_matrix{hemisphere}(:,all_nan_days) = [];
    time_matrix{hemisphere}(:,all_nan_days) = [];
    stim_matrix{hemisphere}(:,all_nan_days) = [];
    LFP_norm_matrix{hemisphere} = (LFP_matrix{hemisphere}-nanmean(LFP_matrix{hemisphere}))./nanstd(LFP_matrix{hemisphere});
end

%% Add raw, normalized, and timestamp data to a combined cell array of all patients

if exist('percept_data','var') && any(strcmp(subject_name,percept_data.days(:,1))) % Appending data to existing subject
    subject_idx = find(strcmp(subject_name,percept_data.days(:,1)));
else %Adding new row
    if ~exist('percept_data','var') % First patient in list
        subject_idx = 1;
    else
        subject_idx = size(percept_data.days,1)+1; % Adding new subject to next row
    end

    percept_data.days{subject_idx,1} = subject_name;
    percept_data.time_matrix{subject_idx,1} = subject_name;
    percept_data.LFP_norm_matrix{subject_idx,1} = subject_name;
    percept_data.LFP_raw_matrix{subject_idx,1} = subject_name;
    percept_data.stim_matrix{subject_idx,1} = subject_name;
    percept_data.raw_data{subject_idx,1} = subject_name;
end

percept_data.raw_data{subject_idx,2} = raw_data;
for hemisphere = 1:2 %2nd column is left hem, 3rd column is right hem
    percept_data.days{subject_idx,hemisphere+1} = DBS_time{hemisphere}';
    percept_data.time_matrix{subject_idx,hemisphere+1} = time_matrix{hemisphere};
    percept_data.LFP_norm_matrix{subject_idx,hemisphere+1} = LFP_norm_matrix{hemisphere};
    percept_data.LFP_raw_matrix{subject_idx,hemisphere+1} = LFP_matrix{hemisphere};
    percept_data.stim_matrix{subject_idx,hemisphere+1} = stim_matrix{hemisphere};
end

end