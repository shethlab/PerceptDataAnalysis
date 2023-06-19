
import numpy as np 
import pandas as pd 
import matlab.engine
eng = matlab.engine.start_matlab()
import datetime
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.graph_objects as go
import EntropyHub as EH
import plotly.io as pio

import os
os.environ["PATH"] = os.environ["PATH"] +  "C:\\Users\\Anth2\\Desktop\\Percept Circadian ML\\env\\lib\\site-packages\\kaleido\\executable\\"

time = [datetime.time(i // 60, i % 60) for i in range(0,1440,10)]

pt001 = pd.DataFrame(eng.eval("load('filled.mat').filled{1,2};"), index= time, columns= eng.eval("load('VCVS_all_filled.mat').comb_days{1,1};")[0])
pt002 = pd.DataFrame(eng.eval("load('filled.mat').filled{2,2};"), index= time, columns= eng.eval("load('VCVS_all_filled.mat').comb_days{2,1};")[0]) 
pt004 = pd.DataFrame(eng.eval("load('filled.mat').filled{3,2};"), index= time, columns= eng.eval("load('VCVS_all_filled.mat').comb_days{3,1};")[0]) 
pt005 = pd.DataFrame(eng.eval("load('filled.mat').filled{4,2};"), index= time, columns= eng.eval("load('VCVS_all_filled.mat').comb_days{4,1};")[0]) 
pt006 = pd.DataFrame(eng.eval("load('filled.mat').filled{5,2};"), index= time, columns= eng.eval("load('VCVS_all_filled.mat').comb_days{5,1};")[0]) 

g01 = [*[0 for i in range(49)], *[1 for i in range(48)], *[2 for i in range(53)]]
pt001.loc['Group'] = g01

g02 = [*[0 for i in range(7)],*[1 for i in range(16)], *[2 for i in range(15)], *[3 for i in range(61)]]
pt002.loc['Group'] = g02

g04 = [*[0 for i in range(10)],*[1 for i in range(9)], *[2 for i in range(69)], *[3 for i in range(186)]]
pt004.loc['Group'] = g04

g05 = [*[0 for i in range(45)],*[1 for i in range(5)], *[2 for i in range(90)], *[3 for i in range(179)]]
pt005.loc['Group'] = g05

g06 = [*[0 for i in range(14)],*[1 for i in range(187)]]
pt006.loc['Group'] = g06

vdict = {}
for pt, name in zip([pt001, pt002, pt004, pt005, pt006], ['PT001', 'PT002', 'PT004', 'PT005', 'PT006']):
    vdict[name] = {}

rad = np.array([.0436332*i for i in range(144)])

r = 3.6


for pt, name in zip([pt001, pt002, pt004, pt005, pt006], ['PT001', 'PT002', 'PT004', 'PT005', 'PT006']):
    pdbs_y = []
    pdbs_x = []
    pt = pt.T
    pdbs = pt[pt['Group'] == 0].iloc[:,:-1].dropna()
    for day in range(pdbs.shape[0]):
        pdbs_y.append(EH.SampEn(pdbs.iloc[day,:].to_numpy(), m = 2, r = r, tau = 1, Logx = np.exp(1))[0][2])
        pdbs_x.append(name)
    vdict[name]['Pre-DBS'] = {'X': pdbs_x, 'Y': pdbs_y}



for pt, name, group in zip([pt002, pt006], ['PT002', 'PT006'],[1, 1]):
    podbs_y = []
    podbs_x = []
    pt = pt.T
    if name == 'PT002':
        podbs = pt[(pt['Group'] == 1) | (pt['Group'] == 3)].iloc[:,:-1].dropna()
    else:
        podbs = pt[pt['Group'] == group].iloc[:,:-1].dropna()
    for day in range(podbs.shape[0]):
        podbs_y.append(EH.SampEn(podbs.iloc[day,:].to_numpy(), m = 2, r = r, tau = 1, Logx = np.exp(1))[0][2])
        podbs_x.append(name)
    vdict[name]['Long'] = {'X': podbs_x, 'Y': podbs_y}


for pt, name, group in zip([pt001,pt004, pt005], ['PT001','PT004', 'PT005'],[2,3,3]):
    well_y = []
    well_x = []
    pt = pt.T
    
    wedbs = pt[pt['Group'] == group].iloc[:,:-1].dropna()

    for day in range(wedbs.shape[0]):
        well_y.append(EH.SampEn(wedbs.iloc[day,:].to_numpy(), m = 2, r = r, tau = 1, Logx = np.exp(1))[0][2])
        well_x.append(name)
    vdict[name]['Long'] = {'X': well_x, 'Y': well_y}

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

fig = go.Figure()
pointpos_male = [-.25,-1.1,-0.8,-0.3,-.3]
pointpos_female = [0.6,0.3,1,1.2,.4]

for count, pt in enumerate([4,1,5,6,2]):

    fig.add_trace(go.Violin(x= vdict[f'PT00{pt}']['Pre-DBS']['X'],
                            y= vdict[f'PT00{pt}']['Pre-DBS']['Y'],
                            legendgroup='M', scalegroup='M', name='Pre-DBS',
                            side='negative',
                            pointpos=pointpos_male[count],
                            showlegend= False,
                            line_color= 'rgb(255,215,0)', 
                            spanmode = 'soft')
                )
    
    if pt == 2 or pt == 6:
        long_color = 'rgb(127,63,152)'
    else:
        long_color = 'rgb(50,50,255)'
        
    q1_p = np.percentile(vdict[f'PT00{pt}']['Pre-DBS']['Y'], 25)
    q3_p = np.percentile(vdict[f'PT00{pt}']['Pre-DBS']['Y'], 75)
    q2_p = np.percentile(vdict[f'PT00{pt}']['Pre-DBS']['Y'], 50)
    
    x0 = count
    fig.add_shape(type="line",
                  x0=x0, y0=q1_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][0], y1=q1_p,
                  line=dict(color='rgb(255,215,0)', width=2, dash = '4px 4px'))
    fig.add_shape(type="line",
                  x0=x0, y0=q3_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][2], y1=q3_p,
                  line=dict(color='rgb(255,215,0)', width=2, dash = '4px 4px'))
    fig.add_shape(type="line",
                  x0=x0, y0=q2_p, x1= x0 - line_dict[f'PT00{pt}']['Pre'][1], y1=q2_p,
                  line=dict(color='rgb(255,215,0)', width=2, dash = '4px 4px'))
        
    fig.add_trace(go.Violin(x= vdict[f'PT00{pt}']['Long']['X'],
                            y= vdict[f'PT00{pt}']['Long']['Y'],
                            legendgroup='F', scalegroup='F', name='Long-Term Status',
                            side='positive',
                            pointpos=pointpos_female[count],
                            showlegend= False,
                            line_color= long_color,
                            spanmode = 'soft')
                )
    
    q1_l = np.percentile(vdict[f'PT00{pt}']['Long']['Y'], 25)
    q3_l = np.percentile(vdict[f'PT00{pt}']['Long']['Y'], 75)
    q2_l = np.percentile(vdict[f'PT00{pt}']['Long']['Y'], 50)
    
    fig.add_shape(type="line",
                  x0=x0, y0=q1_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][0], y1=q1_l,
                  line=dict(color=long_color, width=2, dash = '4px 4px'))
    fig.add_shape(type="line",
                  x0=x0, y0=q3_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][2], y1=q3_l,
                  line=dict(color=long_color, width=2, dash = '4px 4px'))
    fig.add_shape(type="line",
                  x0=x0, y0=q2_l, x1= x0 + line_dict[f'PT00{pt}']['Long'][1], y1=q2_l,
                  line=dict(color=long_color, width=2, dash = '4px 4px'))



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
fig.show()

#pio.write_image(fig, "violin_entropy_responders.eps", )
