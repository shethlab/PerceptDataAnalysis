# Import the necessary libraries 
import numpy as np 
import pandas as pd 
import matlab.engine
import plotly.graph_objects as go


# Constants to determine the hemisphere and the responder/non-responder status of patients
HEMISPHERE = 1 # 1 for Left hemisphere and 2 for right hemisphere
RESPONDER = [1, 4, 5]
NON_RESPONDER = [2, 6]
PRE_DBS_COLOR = 'rgb(255,215,0)'
RESPONDER_COLOR = 'rgb(50,50,255)'
NON_RESPONDER_COLOR = 'rgb(127,63,152)'


#                                     GRAPHING PARAMETERS                                             #
#######################################################################################################
line_dict = {}
for x in [1,2,4,5,6]:
    line_dict[f'PT00{x}'] = {}
    line_dict[f'PT00{x}']['Pre'] = ()

line_dict[f'PT001']['Pre'] = (.44, .49, .29)
line_dict[f'PT001']['Long'] = (.07, .05, .04)
line_dict[f'PT002']['Pre'] = (.02,.02,.01)
line_dict[f'PT002']['Long'] = (.07,.08,.06)
line_dict[f'PT004']['Pre'] = (.05, .055, .053)
line_dict[f'PT004']['Long'] = (.19, .23, .15)
line_dict[f'PT005']['Pre'] = (.31, .3, .25)
line_dict[f'PT005']['Long'] = (.31, .39, .27)
line_dict[f'PT006']['Pre'] = (.075, .095, .098)
line_dict[f'PT006']['Long'] = (.33, .5, .36)
########################################################################################################


# Function to create a pandas DataFrame by loading data from a .mat file
def create_dataframe(mat_file, eng, num):
    # Load the entropy data from the .mat file
    data = pd.DataFrame(eng.eval(f"load('{mat_file}').percept_data.entropy{{{num},{HEMISPHERE+1}}};"))
    # Load the label data from the .mat file
    labels = pd.DataFrame(eng.eval(f"load('{mat_file}').percept_data.grouplabels{{{num},{HEMISPHERE+1}}};"))
    # Concatenate data and labels DataFrames
    concat = pd.concat([data,labels]).T
    concat.columns = ['Sample_Entropy', 'Labels']
    return concat

def main():
    # Initialize MATLAB engine
    eng = matlab.engine.start_matlab()
    
    fig = go.Figure()
    pointpos_male = [-.25,-1.1,-0.8,-0.3,-.3]
    pointpos_female = [0.6,0.3,1,1.2,.4]

    # Iterate over the patients
    for count, pt in enumerate([4,1,5,6,2]): 
        # Create a DataFrame for the patient data
        all_data  = create_dataframe('004_test.mat', eng, pt)
        # Select rows where Labels are either 0 or 1
        pre_dbs = all_data[(all_data['Labels'] == 0)]
        chronic = all_data[(all_data['Labels'] == 1)]

        # Add the Pre-DBS data to the violin plot
        fig.add_trace(go.Violin(x= [f'PT00{pt}' for i in range(pre_dbs.shape[0])],
                                y= pre_dbs['Sample_Entropy'],
                                legendgroup='M', scalegroup='M', name='Pre-DBS',
                                side='negative',
                                pointpos=pointpos_male[count],
                                showlegend= False,
                                line_color= PRE_DBS_COLOR, 
                                spanmode = 'soft')
                    )
                
        # Calculate quartiles for the Pre-DBS data
        q1_p = np.percentile(pre_dbs['Sample_Entropy'], 25)
        q3_p = np.percentile(pre_dbs['Sample_Entropy'], 75)
        q2_p = np.percentile(pre_dbs['Sample_Entropy'], 50)
        
        x0 = count
        # Add lines to the plot representing the quartiles for the Pre-DBS data
        fig.add_shape(type="line",
                    x0=x0, y0=q1_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][0], y1=q1_p,
                    line=dict(color=PRE_DBS_COLOR, width=2, dash = '4px 4px'))
        fig.add_shape(type="line",
                    x0=x0, y0=q3_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][2], y1=q3_p,
                    line=dict(color=PRE_DBS_COLOR, width=2, dash = '4px 4px'))
        fig.add_shape(type="line",
                    x0=x0, y0=q2_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][1], y1=q2_p,
                    line=dict(color=PRE_DBS_COLOR, width=2, dash = '4px 4px'))
        
        # Determine the color for the long-term status data
        if pt in NON_RESPONDER:
            long_color = NON_RESPONDER_COLOR
        else:
            long_color = RESPONDER_COLOR
            
        # Add the long-term status data to the violin plot
        fig.add_trace(go.Violin(x= [f'PT00{pt}' for i in range(chronic.shape[0])],
                                y= chronic['Sample_Entropy'],
                                legendgroup='F', scalegroup='F', name='Long-Term Status',
                                side='positive',
                                pointpos=pointpos_female[count],
                                showlegend= False,
                                line_color= long_color,
                                spanmode = 'soft')
                    )
        
        # Calculate quartiles for the long-term status data
        q1_l = np.percentile(chronic['Sample_Entropy'], 25)
        q3_l = np.percentile(chronic['Sample_Entropy'], 75)
        q2_l = np.percentile(chronic['Sample_Entropy'], 50)
        
        # Add lines to the plot representing the quartiles for the long-term status data
        fig.add_shape(type="line",
                    x0=x0, y0=q1_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][0], y1=q1_l,
                    line=dict(color=long_color, width=2, dash = '4px 4px'))
        fig.add_shape(type="line",
                    x0=x0, y0=q3_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][2], y1=q3_l,
                    line=dict(color=long_color, width=2, dash = '4px 4px'))
        fig.add_shape(type="line",
                    x0=x0, y0=q2_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][1], y1=q2_l,
                    line=dict(color=long_color, width=2, dash = '4px 4px'))

    # Configure the layout of the plot
    fig.update_layout(height = 600, width = 1500,
        violingap=0, violingroupgap=0, violinmode='overlay')
    fig.update_layout(
        plot_bgcolor='white'
    )
    fig.update_traces(meanline={'color': 'black', 'visible': False},
                    points='all', # show all points
                    jitter=0.05,  # add some jitter on points for better visibility
                    scalemode='count') #scale violin plot area with total count
    fig.update_xaxes(showline=True, linewidth=2, linecolor='black')
    fig.update_yaxes(showline=True, linewidth=1, linecolor='black')

    # Display the plot
    fig.show()

if __name__ == '__main__':
    main()
