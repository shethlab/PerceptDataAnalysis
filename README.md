# PerceptDataAnalysis
Details of Code involved in the analysis of data from Medtronic Percept PC
## computeSpectrum
computeSpectrum takes in a time domain stream and outputs the result of spectral analysis in the form of an LFP amplitude for each frequency in the desired range. This function is intended to reconstruct the snapshot spectra provided by Medtronic's Percept PC device.

The function in takes raw data and a frequency array specifying the exact frequencies to compute the LFP amplitude. First, it multiplies the raw data by $\pi/2$ to convert it from units of $\textnormal{uV}$ to $\textnormal{uVp}$. This factor is included after review of [Thenaisie et al.](https://iopscience.iop.org/article/10.1088/1741-2552/ac1d5b) and is intended to scale average voltage to peak voltage ($2/\pi$ is the average magnitude of a sine wave of unit amplitude over its period).

After scaling the raw data, Power Spectral Density is [estimated via Welch's method](https://www.mathworks.com/help/signal/ref/pwelch.html) using a window size of 1 second and overlap size of 0.6 seconds wtih a 256 point FFT. After computing the PSD, LFP amplitude is computed as $\sqrt{\textnormal{PSD}}$. This LFP amplitude in units of $\textnormal{uVp}$ is calculated at each frequency bin, and the result is returned as a vector along with an array of frequencies at which the amplitude was calculated.

We experimentally show that this method is similar to the on-chip algorithm. We recorded two consecutive snapshots (30 second LFP streams converted to LFP amplitude spectra on-board the device). Immediately afterwards, we recorded 1 minute of BrainSense TimeDomain (1 minute of raw LFP data). We then selected a 30 second window of LFP data and applied computeSpectrum to it to compute an LFP amplitude spectrum. We plotted the data from each snapshot along with the computed LFP amplitude spectrum to show their agreement bilaterally (data gathered from STN). ![Fig1Alterted](https://user-images.githubusercontent.com/68879124/229304473-6b51a723-8184-4bc5-ba45-63ad5841c7a1.png)

Notably, this comparison requires us to be confident that the neural activity we recorded during the 1 minute time domain streaming is similar to that during the recorded LFP snapshots. This is likley true since we minimize the amount of time between snapshot recording and time domain recording, and both recordings were taken at rest. However, towards the end of the 1 minute time domain recording, we encountered some artifacts which strongly affect the power spectrum. We did not include segments containing these artifacts in our analysis/comparison detailed above; the relevant artifact and spectral distortion are shown below (data gathered from VC/VS).

![Fig2](https://user-images.githubusercontent.com/68879124/229225749-2cfea2a8-2f9d-43a8-980d-ad9e4868cd61.png)

# System Requirements
## Hardware requirements
package requires only a standard computer with enough RAM to support the in-memory operations.

## Software requirements
### OS Requirements
This package is supported for Windows 11. The package has been tested on the following systems:
+ Windows 11

### Python Dependencies
```
numpy
pandas
matlab-engine
datetime
sklearn
EntropyHub
```

### MATLAB Dependencies

System requirements:
All MATLAB code run on version 2022b using Windows 11
Windows Requirements: https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/support/sysreq/files/system-requirements-release-2022b-windows.pdf

Installation guide:
Mathworks MATLAB 2022b: https://www.mathworks.com/downloads
    ~30 minute installation
Respective version of the Signal Processing Toolbox: https://www.mathworks.com/products/signal.html
    ~5 minute installation
EntropyHub Toolbox v0.2: https://github.com/MattWillFlood/EntropyHub
    ~5 minute installation

Demo:
Data files
 - VCVS_all_daily_stats.mat
 - VCVS_all_5day_stats.mat
 - GPI_all_daily_stats.mat
 - GPI_all_5day_stats.mat (but we do not include R2 or amp for GPi)
Total Preprocessing and plotting runtime: <5 minutes
* Only use "...5day_stats.mat" when plotting R2 or amplitude *
acrophase_plots.m - run to produce polar cosinor plots
circadian_heat_map.m - run to produce spectrogram heat maps
plotTemplates.m - run to produce circular or unwrapped plots of single-day or whole-epoch median 9 Hz power
    - uses zoneTemplateGeneration.m for plotting, any figure edits should occur here
PSD_generation_subplot.m - run to visualize intraop 9 Hz peak with PSD for each patient
stat_calculations.m - calculate sample entropy for each data stream (should this be first?)
stat_gif_plot.m - run to flip through every single day template for a patient
stat_over_time.m - run to visualize sample entropy, R2, or cosinor fit amplitude over time for each patient

Instructions for use:
All code is configured to run after replacing load paths with file locations on local device
Plotting code can be run in any order, all depend on the same input file
