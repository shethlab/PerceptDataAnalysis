function allStats = detailedStats(x,y)
%% Return Detailed Statistics obtained from testing H0 that x ~ y
[~,p,ci,stats] = ttest2(x,y,'Vartype','unequal');
effect = meanEffectSize(x,y,'VarianceType','unequal');
allStats.pvalue = p;
allStats.CI = ci;
allStats.tStat = stats.tstat;
allStats.df = stats.df;
allStats.effectSize = effect;
end