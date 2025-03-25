import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import pandas as pd

def plot_heatmap(LFP, pt_name):

    #pt_params = pd.read_json('')[pt_name]

    days = LFP.columns

    filled_LFP = pd.DataFrame(index=LFP.index, columns=np.arange(days[0], days[-1]))

    # Fill in missing days with NaN values
    for day in filled_LFP.columns:
        if day in days:
            filled_LFP[day] = LFP[day]
        else:
            filled_LFP[day] = np.nan
    
    # Find indices of each response zone
    """ if pt_params['responder_status'] == -1:
        responder_idx = -1
    else:
        responder_idx = pt_params['responder_day']

    if np.isnan(pt_params['hypomanic_days']).all():
        manic_idx = []
    else:
        manic_idx = pt_params['hypomanic_days'] """

    # Initialize plot
    fig, axs = plt.subplots(1, 1, sharey=True, sharex=True, figsize=(len(filled_LFP.columns)*0.1, 10))

    # Heatmap plot
    p = axs.imshow(filled_LFP, aspect=1, cmap='jet')
    fig.colorbar(p, ax=axs)

    # Add vertical line for DBS onset
    axs.vlines(np.where(filled_LFP.columns == 0)[0], -10, len(filled_LFP.index)+5, colors='r', linestyles='dashed', linewidth=2, label='DBS Onset')

    # Add label for Pre-DBS data
    pre_DBS_rect = patches.Rectangle((0, -10), abs(filled_LFP.columns[0]), 5, facecolor='gold', label='Pre-DBS')
    axs.add_patch(pre_DBS_rect)

    # Add corresponding label for Post-DBS data
    """ if manic_idx != []:
        manic_rect = patches.Rectangle((manic_idx[0] + abs(days[0]), -10), manic_idx[1] - manic_idx[0], 5, facecolor='red', label='Hypomania')
        axs.add_patch(manic_rect)

    if responder_idx != -1:
        axs.vlines(np.where(days == responder_idx), -10, len(LFP.index)+5, colors='black', linestyles='dashed', linewidth=2, label='Repsonse Day')
 """
    
    # Adjust figure
    plt.xlabel('Day')
    plt.ylabel('Time of Day')
    plt.xticks(np.arange(0, len(filled_LFP.columns), len(filled_LFP.columns) // 10), filled_LFP.columns[::11])
    plt.yticks(np.arange(0, len(filled_LFP.index), 71), ['0:00', '12:00', '24:00'])
    plt.title(pt_name)
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper right')
    plt.tight_layout()

    #TODO: Add path to save figure to
    plt.savefig("")


def main(pt_names):
    for pt_name in pt_names:
        #TODO: Add path to LFP data and sheet name
        LFP = pd.read_excel("", sheet_name='', index_col=0)
        plot_heatmap(LFP, pt_name)

if __name__ == "__main__":
    pt_names = [''] #TODO: Add patient names
    main(pt_names)