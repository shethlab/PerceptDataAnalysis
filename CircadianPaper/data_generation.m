%% Choosing files and DBS onset date

clearvars -except percept_data zone_index

[fileName,path]=uigetfile('*.json','MultiSelect','on');
fileList=fullfile(path,fileName);

time_zone='America/Chicago';
DBS_onset=input('Input the date of DBS onset in the format dd-MMM-yyyy (e.g 01-Jan-2000): ','s');
DBS_onset=datetime(DBS_onset,'InputFormat','dd-MMM-yyyy','TimeZone',time_zone);

%% Raw data, normalized data, and timestamps

dates=[];
LFP=[];
stim=[];

%Import and concatenate data from JSONs
for i=1:length(fileList)
    LFP_trend = extract(fileList{i});
    if ~isempty(LFP_trend)
        dates = [dates;LFP_trend.time];
        LFP = [LFP,LFP_trend.LFP_amp];
        stim = [stim,LFP_trend.stim_amp];
    end
end

dates.TimeZone=time_zone;

%Remove duplicate data points
[unique_dates,unique_index,~]=unique(dates);
LFP=LFP(:,unique_index);
stim=stim(:,unique_index);

%Discretize data timepoints into 10 minute time-of-day (TOD) bins without date
time_hist=minutes(0:10:25*60); %generate 10 minute bins b/w 0:00 to 25:00 (daylight savings shows up as >24 hr)
disc_TOD=discretize(timeofday(unique_dates),time_hist);
disc_TOD(disc_TOD>24*6)=disc_TOD(disc_TOD>24*6)-24*6; %Shift daylight savings TOD by 24 hours to make it <24 hr

%Discretize data timepoints into dates without times
rounded_dates=dateshift(unique_dates,'start','day');
unique_rounded_dates=unique(rounded_dates);

%Reshape raw data into a 2D matrix with rows=TOD and columns=date
LFP_matrix{1}=nan(24*6,length(unique_rounded_dates));
LFP_matrix{2}=nan(24*6,length(unique_rounded_dates));

for i=1:length(unique_rounded_dates)
    [~,idx]=ismember(rounded_dates,unique_rounded_dates(i));
    LFP_matrix{1}(disc_TOD(idx>0),i)=LFP(1,idx>0);
    time_matrix{1}(disc_TOD(idx>0),i)=unique_dates(idx>0);

    LFP_matrix{2}(disc_TOD(idx>0),i)=LFP(2,idx>0);
    time_matrix{2}(disc_TOD(idx>0),i)=unique_dates(idx>0);
end

%Generate per-hemisphere data cells 
for hemisphere=1:2
    %Find days with no data to remove
    all_nan_days=all(isnan(LFP_matrix{hemisphere}));
    
    %List of dates containing data relative to DBS onset
    unique_cal_days=unique_rounded_dates(~all_nan_days);
    DBS_time{hemisphere}=round(days(unique_cal_days-DBS_onset));
    time_matrix{hemisphere}=days(time_matrix{hemisphere}-DBS_onset);

    %Remove empty days from LFP data matrix and create nan-filled, outlier-removed, per-day normalized matrix
    LFP_matrix{hemisphere}(:,all_nan_days)=[];
    LFP_filled=fillData(LFP_matrix{hemisphere},DBS_time{hemisphere});
    LFP_norm_matrix{hemisphere}=(LFP_filled-nanmean(LFP_filled))./nanstd(LFP_filled);
end

%% Add raw, normalized, and timestamp data to a combined cell array of all patients

subject_name=input('Enter the name for the subject: ','s');

%Initialize combined patient cell array if it does not already exist
if ~exist('percept_data','var')
    percept_data.days={};
    percept_data.LFP_norm_matrix={};
    percept_data.LFP_raw_matrix={};
end

subject_idx=size(percept_data.days,1)+1;

%Add data to the next row of the combined cell array
for hemisphere=1:2
    %Column 1 is the subject ID
    percept_data.days{subject_idx,1}=subject_name;
    percept_data.time_matrix{subject_idx,1}=subject_name;
    percept_data.LFP_norm_matrix{subject_idx,1}=subject_name;
    percept_data.LFP_raw_matrix{subject_idx,1}=subject_name;
    
    %Column 2 is left hemisphere data, column 3 is right hemisphere data
    percept_data.days{subject_idx,hemisphere+1}=DBS_time{hemisphere};
    percept_data.time_matrix{subject_idx,hemisphere+1}=time_matrix{hemisphere};
    percept_data.LFP_norm_matrix{subject_idx,hemisphere+1}=LFP_norm_matrix{hemisphere};
    percept_data.LFP_raw_matrix{subject_idx,hemisphere+1}=LFP_matrix{hemisphere};
end

clearvars -except percept_data t2