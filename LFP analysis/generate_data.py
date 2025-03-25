"""
generate_data.py

This script processes neural data for a given subject, handling raw data,
normalizing it, and organizing it into matrices based on timestamps. The
final data is stored in a nested dictionary structure with specific fields.

Find out more about this script by visiting the following link: https://github.com/shethlab/PerceptDataAnalysis/blob/main/CircadianPaper/generate_data.m

Functions:
    generate_data(subject_name: str, percept_data: Optional[dict] = None, param: dict, 
                  zone_index: Optional[dict] = None, time_zone: str = 'America/Chicago', 
                  file_list: Optional[List[str]] = None) -> Tuple[dict, dict]


"""

import numpy as np
import pandas as pd
import utils
from datetime import datetime, time
import pytz
from typing import Optional, Tuple, List

def generate_data(
    subject_name: str, 
    param: dict,
    percept_data: Optional[dict] = None,  
    zone_index: Optional[dict] = None, 
    time_zone: str = 'America/Chicago', 
    file_list: Optional[List[str]] = None
) -> Tuple[dict, dict]:
    """
    Process percept-medtronic neural data for a given subject and organize it into a nested dictionary structure.

    Parameters:
        subject_name (str): The ID of the subject whose data will be added (e.g., "B001").
        param (dict): Parameters dictionary containing additional information such as 'dbs_date', 'zone_idx', etc.
        percept_data (dict, optional): Existing percept data dictionary to add this patient data to. Defaults to None.
        param (dict): Parameters dictionary containing additional information such as 'dbs_date', 'zone_idx', etc.
        zone_index (dict, optional): Existing zone index dictionary to add this patient data to. Defaults to None.
        time_zone (str, optional): Time zone for the data. Defaults to 'America/Chicago'.
        file_list (list, optional): List of JSON files to process. Defaults to None.

    Returns:
        Tuple[dict, dict]: Updated percept_data nested dictionary and zone_index dictionary.
    """
    # Load files and set up time zone
    if file_list is None:
        print('Error: No files inputed')
        return 
    time_zone = pytz.timezone(time_zone)
    
    DBS_onset_str = param['dbs_date']
    DBS_onset = datetime.strptime(DBS_onset_str, '%m-%d-%Y')
    DBS_onset = time_zone.localize(DBS_onset)

    # Load or initialize raw data
    if percept_data and subject_name in percept_data.get('raw_data', {}):
        raw_data = percept_data['raw_data'][subject_name]
    else:
        raw_data = pd.DataFrame()

    # Import and concatenate data from JSON files
    for filepath in file_list:
        raw = utils.extract_json(filepath)
        if not raw.empty:
            raw_data = pd.concat([raw_data, raw], ignore_index=True)

    if 'Timestamp' not in raw_data.columns:
        raise KeyError('Timestamp column is missing in the raw data')

    raw_data['Timestamp'] = pd.to_datetime(raw_data['Timestamp']).dt.tz_convert(time_zone)

    # Remove duplicate data points
    raw_data = raw_data.drop_duplicates(subset=['Timestamp'])
    unique_dates = raw_data['Timestamp']
    
    # Discretize data timepoints into 10-minute time-of-day (TOD) bins
    time_hist = np.arange(0, 25*60 + 1, 10)
    unique_dates = pd.to_datetime(unique_dates)
    time_of_day_minutes = (unique_dates - unique_dates.dt.floor('D')).view('int64') / (60 * 1e9)
    disc_TOD = np.digitize(time_of_day_minutes, time_hist)
    disc_TOD[disc_TOD > 24*6] -= 24*6
    
    # Discretize data timepoints into dates without times
    rounded_dates = unique_dates.dt.floor('d')
    unique_rounded_dates = np.unique(rounded_dates)

    # Initialize matrices for LFP and stimulation data
    LFP_matrix = {1: np.full((144, len(unique_rounded_dates)), np.nan), 2: np.full((144, len(unique_rounded_dates)), np.nan)}
    stim_matrix = {1: np.full((144, len(unique_rounded_dates)), np.nan), 2: np.full((144, len(unique_rounded_dates)), np.nan)}
    time_matrix = {1: np.full((144, len(unique_rounded_dates)), np.nan, dtype='datetime64[ns]'), 2: np.full((144, len(unique_rounded_dates)), np.nan, dtype='datetime64[ns]')}

    disc_TOD_radix = disc_TOD - 1
    
    # Populate matrices with data
    for i, unique_date in enumerate(unique_rounded_dates):
        idx = np.where(np.isin(rounded_dates, unique_date))[0]
        
        LFP_matrix[1][disc_TOD_radix[idx], i] = raw_data.iloc[idx]['LFP Amp Left'].values
        time_matrix[1][disc_TOD_radix[idx], i] = unique_dates.iloc[idx].values
        stim_matrix[1][disc_TOD_radix[idx], i] = raw_data.iloc[idx]['Stim Amp Left'].values

        LFP_matrix[2][disc_TOD_radix[idx], i] = raw_data.iloc[idx]['LFP Amp Right'].values
        time_matrix[2][disc_TOD_radix[idx], i] = unique_dates.iloc[idx].values
        stim_matrix[2][disc_TOD_radix[idx], i] = raw_data.iloc[idx]['Stim Amp Right'].values
    
    # Generate per-hemisphere data cells
    DBS_time = {}
    LFP_norm_matrix = {}
    LFP_filled_matrix = {}
    for hemisphere in [1, 2]:
        all_nan_days = np.all(np.isnan(LFP_matrix[hemisphere]), axis=0)
        unique_cal_days = unique_rounded_dates[~all_nan_days]

        DBS_onset_naive = pd.to_datetime(DBS_onset)
        unique_cal_days_naive = pd.to_datetime(unique_cal_days)
        time_matrix_naive_flat = pd.to_datetime(time_matrix[hemisphere].ravel()).to_numpy()

        DBS_time[hemisphere] = np.round((unique_cal_days_naive - DBS_onset_naive).total_seconds() / 86400).to_numpy()
        time_matrix_relative = (time_matrix_naive_flat - np.datetime64(DBS_onset_naive)) / np.timedelta64(1, 'D')
        time_matrix_relative[np.isnat(time_matrix_naive_flat)] = np.nan
        time_matrix[hemisphere] = time_matrix_relative.reshape(time_matrix[hemisphere].shape)
            
        # Clean, fill, and z-score LFP data
        LFP_matrix[hemisphere] = LFP_matrix[hemisphere][:, ~all_nan_days]
        LFP_matrix[hemisphere] = utils.oldlead_cleaning(LFP_matrix[hemisphere])
        time_matrix[hemisphere] = time_matrix[hemisphere][:, ~all_nan_days]
        stim_matrix[hemisphere] = stim_matrix[hemisphere][:, ~all_nan_days]
        LFP_norm_matrix[hemisphere] = (LFP_matrix[hemisphere] - np.nanmean(LFP_matrix[hemisphere], axis=0)) / np.nanstd(LFP_matrix[hemisphere], axis=0, ddof=1)
        filled = utils.fill_data(LFP_matrix[hemisphere], DBS_time[hemisphere])
        LFP_filled_matrix[hemisphere] = (filled - np.nanmean(filled, axis=0)) / np.nanstd(filled, axis=0, ddof=1)

    if percept_data is None:
        percept_data = {
            'raw_data': {},
            'days': {},
            'time_matrix': {},
            'LFP_raw_matrix': {},
            'LFP_norm_matrix': {},
            'LFP_filled_matrix': {},
            'stim_matrix': {}
        }
    
    if zone_index is None:
        zone_index = {
            'subject': [],
            'responder': [],
            'non_responder': [],
            'hypomania': []
        }

    # Update zone_index with subject data
    if subject_name in zone_index['subject']:
        subject_idx = zone_index['subject'].index(subject_name)
        if param.get('zone_idx') and param['zone_idx'].lower() == 'y':
            zone_index['responder'][subject_idx] = param['responder_zone_idx']
            zone_index['non_responder'][subject_idx] = param['non_responder_idx']
            zone_index['hypomania'][subject_idx] = ''
    else:
        zone_index['subject'].append(subject_name)
        zone_index['responder'].append(param.get('responder_zone_idx'))
        zone_index['non_responder'].append(param.get('non_responder_idx'))
        zone_index['hypomania'].append(param.get('hypomania'))

    # Update percept_data with processed data
    if subject_name not in percept_data['raw_data']:
        percept_data['raw_data'][subject_name] = raw_data
        percept_data['days'][subject_name] = [None, None]
        percept_data['time_matrix'][subject_name] = [None, None]
        percept_data['LFP_raw_matrix'][subject_name] = [None, None]
        percept_data['LFP_norm_matrix'][subject_name] = [None, None]
        percept_data['LFP_filled_matrix'][subject_name] = [None, None]
        percept_data['stim_matrix'][subject_name] = [None, None]

    percept_data['days'][subject_name][0] = DBS_time[1]
    percept_data['days'][subject_name][1] = DBS_time[2]
    percept_data['time_matrix'][subject_name][0] = time_matrix[1]
    percept_data['time_matrix'][subject_name][1] = time_matrix[2]
    percept_data['LFP_raw_matrix'][subject_name][0] = LFP_matrix[1]
    percept_data['LFP_raw_matrix'][subject_name][1] = LFP_matrix[2]
    percept_data['LFP_norm_matrix'][subject_name][0] = LFP_norm_matrix[1]
    percept_data['LFP_norm_matrix'][subject_name][1] = LFP_norm_matrix[2]
    percept_data['LFP_filled_matrix'][subject_name][0] = LFP_filled_matrix[1]
    percept_data['LFP_filled_matrix'][subject_name][1] = LFP_filled_matrix[2]
    percept_data['stim_matrix'][subject_name][0] = stim_matrix[1]
    percept_data['stim_matrix'][subject_name][1] = stim_matrix[2]

    return percept_data, zone_index


""" Usage:
    Run the script directly to generate data for a subject:
"""
if __name__ == "__main__":
    percept_data = None
    zone_index = None

    #TODO: Enter patient ID and parameters (only 'dbs_date' is required)
    pt_id = ''
    param = {'dbs_date': '', 'zone_idx': 'N', 'responder_zone_idx': 1, 'non_responder_idx': 0, 'hypomania': ''}

    #TODO: Add json file paths in file_list variable
    percept_data, zone_index = generate_data(subject_name=pt_id, 
                                             percept_data=percept_data, 
                                             zone_index=zone_index, 
                                             param=param, 
                                             file_list=[""])
    
    # Possible to save other columns of data using same format as below
    LFP_df_left = pd.DataFrame(percept_data['LFP_filled_matrix'][f'{pt_id}'][0], columns=percept_data['days'][f'{pt_id}'][0], index=[time(i // 60, i % 60) for i in range(0, 1440, 10)])
    LFP_df_right = pd.DataFrame(percept_data['LFP_filled_matrix'][f'{pt_id}'][1], columns=percept_data['days'][f'{pt_id}'][1], index=[time(i // 60, i % 60) for i in range(0, 1440, 10)])

    # Save LFP data to excel file
    #TODO: Adjust path and sheet names accordingly
    with pd.ExcelWriter('', mode='w', engine='openpyxl') as writer:
            LFP_df_left.to_excel(writer, sheet_name="", )
            LFP_df_right.to_excel(writer, sheet_name="", )