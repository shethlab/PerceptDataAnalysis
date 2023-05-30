function distance = distanceMetric(day1, day2)
%% Compute distance using distance metric between 2 days
% day1 and day2 are the same length

try
    distance = dtw(day1,day2,'euclidean');
catch
    distance = nan;
end
end