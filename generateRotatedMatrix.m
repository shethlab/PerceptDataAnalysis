savepath = 'C:\Users\Owner\Desktop\Percept Runnig Circadian Data\SmoothedRotatedCirc.mat';

smoothedRotatedCircadianMatricesDecib = {};

for i = 1:5
    smoothedRotatedCircadianMatrices{i,1} = comb_LFP_logscaled{i,1};
    for j = 2:3
        smoothedRotatedCircadianMatrices{i,j} = smoothRotate(comb_LFP_logscaled{i,j},comb_acro{i,j-1},comb_p{i,j-1});
        
    end

end

%%save(savepath,'smoothedRotatedCircadianMatricesDecib','comb_days');