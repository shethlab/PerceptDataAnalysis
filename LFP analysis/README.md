# LFP Analysis
Detail process to create heatmaps of LFP data. To get a more detailed walkthrough of the generation of the LFP data, check out the PerceptDataAnalysis README in the root directory.

## Python Dependencies
```
numpy==2.2.3
pandas==2.2.3
pytz==2025.1
matplotlib==3.10.0
scikit-learn==1.6.1
scipy==1.15.2
statsmodels==0.14.4
```

# Workflow
Process the LFP data into an excel file using 'generate_data.py' and create the patient heatmap using 'plot_lfp_heatmap.py'. Adjust the file paths and sheet names accordingly for each file in the labeled 'TODO' comments.