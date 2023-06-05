function filledData = fillData(matrix,days)
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