# Import the necessary libraries 
import numpy as np 
import pandas as pd 
import matlab.engine
import plotly.graph_objects as go
import datetime as datetime

# Start MATLAB engine
eng = matlab.engine.start_matlab()

# Constants and Utility Functions
TIME_INDEX = [datetime.time(i // 60, i % 60) for i in range(0, 1440, 10)]  # Create a list of time objects every 10 minutes within a day
PRE_DBS_COLOR = 'rgb(255,215,0)'  # Yellow color for Pre-DBS period data points
RESPONDER_COLOR = 'rgb(50,50,255)'  # Blue color for responder status data points
NON_RESPONDER_COLOR = 'rgb(255,185,0)'  # Orange color for non-responder status data points
METRIC_MAPPING = {'Cosinor': 'cosinor_R2', 'LinearAR': 'linearAR_R2', 'NonlinearAR': 'nonlinearAR_R2', 'Entropy': 'entropy'}  # Mapping of metrics to their data identifiers

def load_metric_data(mat_file: str, pt_id: int, hemi: int, metric: str):
    """
    Load output metric data from a MATLAB .mat file for a given patient and hemisphere in VC/VS.

    Parameters:
    - mat_file (str): Path to the .mat file containing the data.
    - pt_id (int): The patient identifier.
    - hemi (int): Hemisphere identifier (0 for left hemisphere, 1 for right hemisphere).
    - metric (str): Output metric identifier.

    Returns:
    - pd.DataFrame: A dataframe containing output metric data.
    """
    # Create a MATLAB command to load specific patient and hemisphere data
    command = lambda x: f"load('{mat_file}').percept_data.{x}{{{pt_id+1},{2+hemi}}};"
    
    # Load the metric data and create a DataFrame
    store = pd.DataFrame(eng.eval(command(METRIC_MAPPING[metric])), index=['Metric'],
                         columns=eng.eval(command("days"))[0])
    
    # Add state labels to the DataFrame
    store.loc['State Label'] = get_state_labels(mat_file, pt_id+1, store)    
    return store

def get_state_labels(mat_file: str, pt_id: int, master_df: pd.DataFrame):
    """
    Retrieves state labels for each data point in a dataset based on a MATLAB file.

    Parameters:
    - mat_file (str): Path to the MATLAB file containing state information.
    - pt_id (int): Patient identifier.
    - master_df (pd.DataFrame): DataFrame containing the dates for which state labels are needed.

    Returns:
    - np.ndarray: An array of state labels for each column in master_df.
    """
    
    # Initialize state labels array with `inf` to indicate unidentified states initially.
    state_label = np.full(master_df.shape[1], np.inf)

    # Pre-assign '0' for the pre-DBS period.
    state_label[[i for i, date in enumerate(master_df.columns) if date < 0]] = 0

    # Loop through each state defined in the MATLAB file and assign labels accordingly.
    for label, state in enumerate(['hypomania', 'non_responder', 'responder']):
        # Extract days corresponding to each state from the MATLAB file.
        state_days = eng.eval(f"load('{mat_file}').zone_index.{state}{{{pt_id},1}};")
        # Assign labels to the dates matching the extracted days.
        state_label[[i for i, date in enumerate(master_df.columns) if date in np.array(state_days)]] = label + 1

    # Replace `inf` labels with '4' for any data points that remain unlabeled.
    state_label = np.where(state_label == np.inf, 4, state_label)
    
    return state_label

def main(hemi: int, mat_file: str, pt: list, models: list):
    """
    Main function to generate violin plots for each patient and model.
    Plots show the distribution of data points, categorized by pre-DBS, responder, and non-responder states.

    Parameters:
    - hemi (int): Hemisphere identifier (0 for left hemisphere, 1 for right hemisphere).
    - mat_file (str): Path to the .mat file containing the data.
    - pt (list): List of patient identifiers.
    - models (list): List of models (metrics) to plot.

    Returns:
    - None
    """
    for model in models:
        fig = go.Figure()  # Initialize a new figure for each model
        for pt_id, pt_name in enumerate(pt):
            pt_data = load_metric_data(mat_file, pt_id, hemi, model)  # Load data for each patient and model
            
            # Plot Pre-DBS data if available
            if 0 in set(pt_data.loc['State Label']):
                y = pt_data.loc['Metric', pt_data.loc['State Label'] == 0.0]
                fig.add_trace(go.Violin(x=[f'{pt_name}' for i in range(y.shape[0])],
                                        y=y,
                                        legendgroup='M', scalegroup='M', name='Pre-DBS',
                                        side='negative',
                                        showlegend=False,
                                        line_color=PRE_DBS_COLOR, 
                                        spanmode='soft'))

            # Plot Non-Responder data if available
            if 2 in set(pt_data.loc['State Label']):
                y = pt_data.loc['Metric', pt_data.loc['State Label'] == 2.0]
                fig.add_trace(go.Violin(x=[f'{pt_name}' for i in range(y.shape[0])],
                                        y=y,
                                        legendgroup='F', scalegroup='F', name='Chronic Status',
                                        side='positive',
                                        showlegend=False,
                                        line_color=NON_RESPONDER_COLOR,
                                        spanmode='soft'))

            # Plot Responder data if available
            if 3 in set(pt_data.loc['State Label']):
                y = pt_data.loc['Metric', pt_data.loc['State Label'] == 3.0]
                fig.add_trace(go.Violin(x=[f'{pt_name}' for i in range(y.shape[0])],
                                        y=y,
                                        legendgroup='F', scalegroup='F', name='Chronic Status',
                                        side='positive',
                                        showlegend=False,
                                        line_color=RESPONDER_COLOR,
                                        spanmode='soft'))

        # Configure the layout of the plot
        fig.update_layout(height=600, width=1600, violingap=0, violingroupgap=0, violinmode='overlay', title=model, plot_bgcolor='white')
        fig.update_traces(meanline={'color': 'gray', 'visible': True}, points='all', jitter=0.05, scalemode='width') 
        fig.update_xaxes(showline=True, linewidth=2, linecolor='black')
        fig.update_yaxes(showline=True, linewidth=1, linecolor='black')
        if model=='Entropy':
            fig.update_yaxes(range=[0, 0.08])
        else:
            fig.update_yaxes(range=[-.5, 1])
        
        # Display the plot
        fig.show()

if __name__ == "__main__":    
    # Run the main function with specified parameters
    main(hemi,mat_file,pt,models)