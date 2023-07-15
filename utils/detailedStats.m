function allStats = detailedStats(y,x,label)
%% Return Detailed Statistics obtained from testing H0 that x ~ y
allStats.subject = label;
if ~isempty(x) && ~isempty(y)    
    [~,p,ci,stats] = ttest2(x,y,'Vartype','unequal');
    effect = meanEffectSize(x,y,'Effect','cohen','VarianceType','unequal');
    allStats.pvalue = p;
    if allStats.pvalue <.01
        allStats.pvalue = 10^ceil(log10(allStats.pvalue));
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