%% Decibelization + ZScoring options
load('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\VCVS_all.mat');
%% Option 1: Log Data, Zscore
comb_LFP_logscaled = {};
filled_missing = {};
temp = [];
for i = 1:5
    comb_LFP_logscaled{i,1} = comb_LFP_raw_matrix{i,1};
    filled_missing{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        temp = 10*log10(comb_LFP_raw_matrix{i,j});
        comb_LFP_logscaled{i,j} = (temp-mean(temp,1,'omitnan'))./std(temp,0,'omitnan');
        filled_missing{i,j} = fillData(comb_LFP_logscaled{i,j});
% %         for q = 1:width(temp)
% %             d = temp(:,q);
% %             if length(find(isnan(d))) <3
% %                 filled_missing{i,j}(:,q) = fillmissing(d,'pchip');
% %             else
% %                 filled_missing{i,j}(:,q) = d;
% %             end
% %         end
    end
end
save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\logScaledZScoretoMean.mat','comb_LFP_logscaled','filled_missing','comb_days','comb_p','comb_acro');
%% Option 2: Log Mean Normalized Data, Zscore
comb_LFP_logscaled = {};
filled_missing = {};
temp = [];
for i = 1:5
    comb_LFP_logscaled{i,1} = comb_LFP_raw_matrix{i,1};
    filled_missing{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        temp = 10*log10(comb_LFP_raw_matrix{i,j}./mean(comb_LFP_raw_matrix{i,j},1,'omitnan'));
        comb_LFP_logscaled{i,j} = temp./std(temp,0,'omitnan');
        filled_missing{i,j} = fillData(comb_LFP_logscaled{i,j});
% %         for q = 1:width(temp)
% %             d = temp(:,q);
% %             if length(find(isnan(d))) <3
% %                 filled_missing{i,j}(:,q) = fillmissing(d,'pchip');
% %             else
% %                 filled_missing{i,j}(:,q) = d;
% %             end
% %         end
    end
end
save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\logScaledtoMeanZScoretoMean2.mat','comb_LFP_logscaled','filled_missing','comb_days','comb_p','comb_acro');

%% Option 3: Log Data, Zscore to Median
comb_LFP_logscaled = {};
filled_missing = {};
temp = [];
for i = 1:5
    comb_LFP_logscaled{i,1} = comb_LFP_raw_matrix{i,1};
    filled_missing{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        temp = 10*log10(comb_LFP_raw_matrix{i,j});
        comb_LFP_logscaled{i,j} = (temp-median(temp,1,'omitnan'))./(1.4826*mad(temp,1));
        filled_missing{i,j} = fillData(comb_LFP_logscaled{i,j});
% %         for q = 1:width(temp)
% %             d = temp(:,q);
% %             if length(find(isnan(d))) <3
% %                 filled_missing{i,j}(:,q) = fillmissing(d,'pchip');
% %             else
% %                 filled_missing{i,j}(:,q) = d;
% %             end
% %         end
    end
end
save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\logScaledZScoretoMedian.mat','comb_LFP_logscaled','filled_missing','comb_days','comb_p','comb_acro');

%% Option 4: Log Median Normalized Data, Zscore
comb_LFP_logscaled = {};
filled_missing = {};
temp = [];
for i = 1:5
    comb_LFP_logscaled{i,1} = comb_LFP_raw_matrix{i,1};
    filled_missing{i,1} = comb_LFP_raw_matrix{i,1};
    for j = 2:3
        temp = 10*log10(comb_LFP_raw_matrix{i,j}./median(comb_LFP_raw_matrix{i,j},1,'omitnan'));
        comb_LFP_logscaled{i,j} = temp./(1.4826*mad(temp,1));
        filled_missing{i,j} = fillData(comb_LFP_logscaled{i,j});
% %         for q = 1:width(temp)
% %             d = temp(:,q);
% %             if length(find(isnan(d))) <3
% %                 filled_missing{i,j}(:,q) = fillmissing(d,'pchip');
% %             else
% %                 filled_missing{i,j}(:,q) = d;
% %             end
% %         end
    end
end
save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\logScaledtoMedianZScoretoMedian.mat','comb_LFP_logscaled','filled_missing','comb_days','comb_p','comb_acro');

%save('C:\Users\Owner\Desktop\Percept Runnig Circadian Data\ZScoreDecibelizedSingleCosinor.mat','comb_acro', 'comb_amp', 'comb_days', 'comb_LFP_decibelized_norm_mean','comb_LFP_decibelized_norm_mean_filled', 'comb_LFP_decibelized_norm_median','comb_LFP_decibelized_norm_median_filled', 'comb_LFP_norm_matrix', 'comb_LFP_raw_matrix', 'comb_p', 'comb_R2', 'comb_RMSE');