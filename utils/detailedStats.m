function allStats = detailedStats(x,y)
%% Return Detailed Statistics obtained from testing H0 that x ~ y
if ~isempty(x) && ~isempty(y)
    [~,p,ci,stats] = ttest2(x,y,'Vartype','unequal');
    effect = meanEffectSize(x,y,'Effect','cohen','VarianceType','unequal');
    if p*3 >= 1
        allStats.pvalue = 1;
    else
        allStats.pvalue = p*3;
    end
    allStats.tStat = stats.tstat;
    allStats.CI = ci;
    allStats.df = stats.df;
    allStats.effectSize = effect.Effect;
    allStats.effectCI = effect.ConfidenceIntervals;
else
    allStats.pvalue = [];
    allStats.tStat = [];
    allStats.CI = [];
    allStats.df = [];
    allStats.effectSize = [];
    allStats.effectCI = [];
end
    allStats.sampleSizePre = length(y);
    allStats.sampleSizePost = length(x);
end