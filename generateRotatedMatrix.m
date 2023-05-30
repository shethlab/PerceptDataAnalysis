savepath = 'C:\Users\Owner\Desktop\SmoothedRotatedCirc.mat';
load('VCVS_all');
smoothedRotatedCircadianMatrices = {};
for i = 1:7
    smoothedRotatedCircadianMatrices{i,1} = comb_LFP_norm_matrix{i,1};
    for j = 2:3
        smoothedRotatedCircadianMatrices{i,j} = smoothRotate(comb_LFP_norm_matrix{i,j},comb_acro{i,j-1},comb_p{i,j-1});
    end
end

save(savepath,'smoothedRotatedCircadianMatrices','comb_acro','comb_amp','comb_days','comb_p','comb_LFP_raw_matrix','comb_LFP_norm_matrix');