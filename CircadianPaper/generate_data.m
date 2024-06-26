%% This function collates Percept data directly from JSONs into a struct
% variable to be subsequently processed. This code must be run prior to
% any analysis. This function has one required input and three optional:
%   1. subject_name: the ID of the subject whose data will be added (e.g.
%       "B001"). Only use alphanumeric characters and underscores to avoid
%       potential code conflicts.
%   2. percept_data (optional): the name of the Percept data matrix to add
%       this patient data to. To add new patients or update patient data to
%       an existing data struct, enter the name of the existing struct
%       here. If left blank, patient data will be added to a new struct.
%   3. zone_index (optional): the name of the zone index struct to add
%       this patient data to. To add new patients or update patient data to
%       an existing data struct, enter the name of the existing struct
%       here. If left blank, patient data will be added to a new struct. This
%       struct refers to a list of days for each clinical state (see #4 in the
%       following section.)
%   4. time_zone (optional): enter time zone in a MATLAB-standard format
%       (e.g. 'Europe/London'). Defaults to 'America/Chicago' if not provided.
% 
% This function also requests inputs from the user through a UI file prompt
% and in the command line. The following is the order in which inputs are
% prompted:
%   1. Select patient JSON files: a file explorer directory will open. Select
%       the Percept JSON files to analyze. Multiple files can be selected,
%       but ensure to only process one patient and one stimulation target 
%       at a time. All of a patient's files can be selected or just the
%       ones of interest (for example new data). The code will
%       automatically discard duplicates or redundant data.
%   2. Input the date of DBS onset: a command window input in which to type
%       the date of DBS activation. This date is used to convert all
%       chronic data timestamps into relative days since DBS activation.
%   3. Updating the zone index (optional): a command window prompt that
%       arises only if the inputted subject already exists in the data
%       struct. Type "y" or "Y" to update the zone index (description
%       below).
%   4. Updating the zone index: required if adding a new subject or the
%       user selected "y" to input 3. This is a series of command window
%       inputs to specify the day ranges of various clinical behaviors,
%       which are used to distinguish clinical states for statistical
%       analysis. Enter these as MATLAB integer vectors that list every 
%       single day after DBS activation that falls under a particular state
%       (e.g. 1 or [1,5] or 1:5). The following clinical states are queried:
%           - Responder: a time period in which the subject has achieved
%               clinical response as noted by YBOCS criteria. Do not enter
%               any days prior to the start of clinical response in the
%               zone index.
%           - Non-responder: a time period in which the subject does not
%               achieve significant symptom improvement as determined
%               clinically. Note that this is a retroactive determination -
%               once the patient is deemed a clinical nonresponder, the
%               entire post-DBS activation time period can be considered
%               "non-responder." However, for new patients who just
%               activated their DBS, leave any post-DBS days blank until
%               their responder/non-responder status has been determined.
%           - Hypomania: a time period in which the subject experienced
%               significant hypomanic symptoms as determined clinically.
%               This will override the responder/non-responder/blank
%               classifications.
%
% This function has one output:
%   1. percept_data: the updated data structure including all of the input
%       information, as well as the new data. It includes the following
%       fields:
%           - raw_data: a table containing the original, untransformed
%               timestamp as well as LFP & stimulation amplitudes in both
%               hemispheres. This variable is used only for checking
%               redundancy when updating new subject data.
%           - days: a Nx3 cell array (where N is number of subjects), where
%               column one is the subject name, column two is left
%               hemisphere data, and column three is right hemisphere data.
%               Each entry contains a 1D vector of the unique dates of data
%               recording, expressed as integer days since DBS activation.
%           - time_matrix: a Mx3 cell array (where M is the number of unique
%               days). Each entry contains a 2D vector with 144 rows 
%               (corresponding to each 10-minute interval from midnight to 
%               11:50 PM) in which data points are double-precision days 
%               since DBS activation.
%           - LFP_raw_matrix: a Mx3 cell array. Each entry contains a 2D
%               vector with 144 rows in which data points are the raw LFP 
%               signal in uVp.
%           - LFP_norm_matrix: a Mx3 cell array. Each entry contains a 2D
%               vector with 144 rows in which data points are a per-day
%               z-score of the respective values from LFP_raw_matrix. These
%               matrices are used for visualization only (i.e. heatmaps).
%           - LFP_filled_matrix: a Mx3 cell array. Each entry contains a 2D
%               vector with 144 rows in which data points are missing internal
%               data and outliers are filled with pchip interpolation. These
%               matrices are used for calculations.
%           - stim_matrix: a Mx3 cell array. Each entry contains a 2D
%               vector with 144 rows in which data points are the provided
%               stimulation amplitude (in mA) from the device at that time.

function [percept_data,zone_index] = generate_data(subject_name,percept_data,zone_index,time_zone)
    
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

%Import and concatenate data from JSONs
for i = 1:length(fileList)
    raw = extract_JSON(fileList{i});
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
    filled = fillData(LFP_matrix{hemisphere},DBS_time{hemisphere}');
    LFP_filled_matrix{hemisphere} = (filled - nanmean(filled))./nanstd(filled);
end

%% Add raw, normalized, and timestamp data to a combined cell array of all patients

if exist('percept_data','var') && any(strcmp(subject_name,percept_data.days(:,1))) % Appending data to existing subject
    subject_idx = find(strcmp(subject_name,percept_data.days(:,1)));
    zone_update = input('Do you want to update the zone indices (Y or N)? ','s');
    if strcmpi(zone_update,'y')
        zone_index.responder{subject_idx,1} = input('Enter the new responder zone index as an array (leave blank if empty). ');
        zone_index.non_responder{subject_idx,1} = input('Enter the new non-responder zone index as an array (leave blank if empty). ');
        zone_index.hypomania{subject_idx,1} = input('Enter the new hypomania zone index as an array (leave blank if empty). ');
    end
else %Adding new row
    if ~exist('percept_data','var') % First patient in list
        subject_idx = 1;
    else
        subject_idx = size(percept_data.days,1)+1; % Adding new subject to next row
    end

    percept_data.days{subject_idx,1} = subject_name;
    percept_data.time_matrix{subject_idx,1} = subject_name;
    percept_data.LFP_norm_matrix{subject_idx,1} = subject_name;
    percept_data.LFP_filled_matrix{subject_idx,1} = subject_name;
    percept_data.LFP_raw_matrix{subject_idx,1} = subject_name;
    percept_data.stim_matrix{subject_idx,1} = subject_name;
    percept_data.raw_data{subject_idx,1} = subject_name;

    zone_index.responder{subject_idx,1} = input('Enter the new responder zone index as an array (leave blank if empty). ');
    zone_index.non_responder{subject_idx,1} = input('Enter the new non-responder zone index as an array (leave blank if empty). ');
    zone_index.hypomania{subject_idx,1} = input('Enter the new hypomania zone index as an array (leave blank if empty). ');
end

percept_data.raw_data{subject_idx,2} = raw_data;
for hemisphere = 1:2 %2nd column is left hem, 3rd column is right hem
    percept_data.days{subject_idx,hemisphere+1} = DBS_time{hemisphere}';
    percept_data.time_matrix{subject_idx,hemisphere+1} = time_matrix{hemisphere};
    percept_data.LFP_norm_matrix{subject_idx,hemisphere+1} = LFP_norm_matrix{hemisphere};
    percept_data.LFP_filled_matrix{subject_idx,hemisphere+1} = LFP_filled_matrix{hemisphere};
    percept_data.LFP_raw_matrix{subject_idx,hemisphere+1} = LFP_matrix{hemisphere};
    percept_data.stim_matrix{subject_idx,hemisphere+1} = stim_matrix{hemisphere};
end

end
