# PerceptDataAnalysis
Details of Code involved in the analysis of data from Medtronic Percept PC
## computeSpectrum
computeSpectrum takes in a time domain stream and outputs the result of spectral analysis in the form of an LFP amplitude for each frequency in the desired range. This function is intended to reconstruct the snapshot spectra provided by Medtronic's Percept PC device.

The function in takes raw data and a frequency array specifying the exact frequencies to compute the LFP amplitude. First, it multiplies the raw data by $\pi/2$ to convert it from units of $\textnormal{uV}$ to $\textnormal{uVp}$. This factor is included after review of [Thenaisie et al.](https://iopscience.iop.org/article/10.1088/1741-2552/ac1d5b) and is intended to scale average voltage to peak voltage ($2/\pi$ is the average magnitude of a sine wave of unit amplitude over its period).

After scaling the raw data, Power Spectral Density is [estimated via Welch's method](https://www.mathworks.com/help/signal/ref/pwelch.html) using a window size of 1 second and overlap size of 0.6 seconds at each of the frequencies specified in the input frequency array. After computing the PSD, LFP amplitude is computed as $\sqrt{\textnormal{PSD}}$. This LFP amplitude in units of $\textnormal{uVp}$ is calculated at each frequency bin, and the result is returned as a vector along with the frequency array.

We experimentally show that this method is similar to the on-chip algorithm. We recorded two consecutive snapshots (30 second LFP streams converted to LFP amplitude spectra on-board the device). Immediately afterwards, we recorded 1 minute of BrainSense TimeDomain (1 minute of raw LFP data). We then selected a 30 second window of LFP data and applied computeSpectrum to it to compute an LFP amplitude spectrum. We plotted the data from each snapshot along with the computed LFP amplitude spectrum to show their agreement bilaterally. ![Fig1](https://user-images.githubusercontent.com/68879124/229225564-f8ec9e6f-f01c-43f9-be61-0d60474db961.png)


Notably, this comparison requires us to be confident that the neural activity we recorded during the 1 minute time domain streaming is similar to that during the recorded LFP snapshots. This is likley true since we minimize the amount of time between snapshot recording and time domain recording, and the experiment itself lasts only a few minutes in total. However, towards the end of the 1 minute time domain recording, we encountered some artifacts which strongly affect the power spectrum. We did not include segments containing these artifacts in our analysis/comparison detailed above; the relevant artifact and spectral distortion are shown below.

![Fig2](https://user-images.githubusercontent.com/68879124/229225749-2cfea2a8-2f9d-43a8-980d-ad9e4868cd61.png)
