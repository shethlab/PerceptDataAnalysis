function allStats = detailedStats(y,x,label,effective)
%% Returns Detailed Statistics obtained from testing H0 that x ~ y where
% y is pre-DBS and x is post-DBS. Includes standard testing and effective
% sample size-corrected testing.

allStats.subject = label; % Patient name

if isempty(x) || isempty(y) %skip calculation if either group missing
    allStats.pvalue = [];
    allStats.tStat = [];
    allStats.CI = [];
    allStats.df = [];
    allStats.effectSize = [];
    allStats.effectCI = [];
    allStats.sampleSizePre = length(y);
    allStats.sampleSizePost = length(x);
elseif effective == 1 % Effective sample size calculation
    ESS_y = ESS(y); % Effective sample size
    ESS_x = ESS(x);

    var_y = var(y); % Variance
    var_x = var(x);

    pooled_SD = sqrt(((ESS_y - 1)*var_y + (ESS_x - 1)*var_x) / (ESS_y + ESS_x - 2)); % Pooled standard deviation formula
    
    correction_factor = 1 - (3 / (4*(ESS_y + ESS_x) - 9)); % Correction factor formula for hedge's G calculation    
    g = ((mean(x) - mean(y)) / pooled_SD) * correction_factor; % Hedge's g calculation formula
    SE_g = sqrt((ESS_x + ESS_y)/(ESS_x*ESS_y) + g^2/(2*(ESS_x + ESS_y))); % Hedge's g standard error formula

    SE_y = std(y) / sqrt(ESS_y); % Standard error
    SE_x = std(x) / sqrt(ESS_x);
    pooled_SE = sqrt(SE_y^2 + SE_x^2); % Pooled standard error

    tstat = (mean(x) - mean(y))/pooled_SE; % Calculate t-stat
    
    % Confidence interval of effect size
    df = ESS_x + ESS_y - 2;
    t_crit = tinv(0.05/2,df) * [1,-1]; % Critical t value for p < 0.05
    ci_g = g + t_crit*SE_g; % Hedge's g confidence interval
    
    % Confidence interval of mean difference
    df = ((SE_y^2 + SE_x^2)^2) / ((SE_y^4 / (ESS_y - 1)) + (SE_x^4 / (ESS_x - 1))); % degrees of freedom using Satterthwaite's approximation
    t_crit = tinv(0.05/2,df) * [1,-1]; % Critical t value for p < 0.05
    ci = (mean(x) - mean(y)) + t_crit*pooled_SE; 

    p = 2*(1 - tcdf(abs(tstat),df)); % 2-tailed p-values

    allStats.pvalue = p;
    if allStats.pvalue <.01 % Express very low p-values in scientific notation
        allStats.pvalue = 10^ceil(log10(allStats.pvalue));
    end

    allStats.tStat = tstat;
    allStats.CI = ci;
    allStats.df = df;
    allStats.effectSize = g;
    allStats.effectCI = ci_g;
    allStats.sampleSizePre = ESS_y;
    allStats.sampleSizePost = ESS_x;
    
else % Standard t-test without effective sample size    
    [~,p,ci,stats] = ttest2(x,y,'Vartype','unequal');
    effect = meanEffectSize(x,y,'Effect','cohen','VarianceType','unequal');
    allStats.pvalue = p;
    if allStats.pvalue <.01 % Express very low p-values in scientific notation
        allStats.pvalue = 10^ceil(log10(allStats.pvalue));
    end

    allStats.tStat = stats.tstat;
    allStats.CI = ci;
    allStats.df = stats.df;
    allStats.effectSize = effect.Effect;
    allStats.effectCI = effect.ConfidenceIntervals;
    allStats.sampleSizePre = length(y);
    allStats.sampleSizePost = length(x);
end

end