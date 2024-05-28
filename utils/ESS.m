%% Calculates effective sample size for a 1D numeric data.

function ESS_x = ESS(x)

x = x(~isnan(x));

if isempty(x)
    ESS_x = 0;
else
    acf_x = autocorr(x,NumLags=min([10,length(x)-1])); % 10 lags of autocorrelation
    acf_sum_x = sum(abs(acf_x(2:end)));
    ESS_x = length(x) / (1 + 2*acf_sum_x);
end

end