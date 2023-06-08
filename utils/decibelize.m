function logScaledData = decibelize(filledRawData)
%% For Visualization as a template: Log Mean Normalized Data, Divide By Standard Deviation
logScaledData  = {};
temp = 10*log10(filledRawData./mean(filledRawData,1,'omitnan'));
logScaledData = temp./std(temp,0,1,'omitnan');
end







