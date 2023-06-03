function filledData = fillData(matrix)
filledData = [];
for q = 1:width(matrix)
    d = matrix(:,q);
    if length(find(isnan(d))) <3
        filledData(:,q) = fillmissing(d,'pchip');
    else
        filledData(:,q) = d;
    end
end