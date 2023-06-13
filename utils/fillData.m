function filledData = fillData(matrix,days)
% fillData intakes a circadian matrix in 2D format, reshapes into a series of 1D chunks of contiguous segments of time,
% and filles outliers and missing values using Piecewise Cubic Hermite Polynomial Interpolation (pchip). Outliers must be 
% 10SD above the mean of the chunk, while nans are filled only if the length of a series of nans is less than 7 (max length of 
% data to be interpolated is 1 hour). 

%% Inputs ---
%  matrix : 2D circadian matrix
%  days: day vector containing day since VCVS DBS On for each column in
%  matrix
%% Outputs ---
% filledData: data with interpolated values reshaped into original 2D
% format 


filledData = [];

start_index=find(diff(days)>1);
try
    start_index=[1,start_index+1,length(days)+1];
catch
    start_index=[1,length(days)+1];
end

comb_1d=[];
for i=1:length(start_index)-1
    matrix1d=reshape(matrix(:,start_index(i):start_index(i+1)-1),[1,144*(start_index(i+1)-start_index(i))]);
    matrix1d=filloutliers(matrix1d,'pchip','mean','ThresholdFactor',10);
    matrix1d=fillmissing(matrix1d,'pchip','MaxGap',7);  
    comb_1d=[comb_1d,matrix1d];
end

filledData=reshape(comb_1d,[size(matrix)]);
end