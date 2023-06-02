function filledData = fillData(matrix)
filledData = [];
for i = 1:width(matrix)
    d = matrix(:,i);
    if length(find(isnan(d))) <3
        filledData(:,q) = fillmissing(d,'pchip');
    else
        filledData(:,q) = d;
    end
end