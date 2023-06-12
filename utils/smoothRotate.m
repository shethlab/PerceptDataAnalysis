  function smoothedRotatedMatrix = smoothRotate(matrix,acrophase,pval,smooth)
%% Function to Rotate Circadian Matrices so Acrophases align and Gaussian Smooth Each Day
%% Inputs -----
%% matrix: 144 x numDays matrix. 
% Row corresponds to time of day, column corresponds to day. Matrix element is recorded
% power in defined recording band.
%% acrophase: Vector containing acrophases (in radians)  for days whose matrix column is non empty
% Days which are empty do not recieve an acrophase
%% pval: Vector containing pvalue for corresponding acrophase. 
% Only dates for which pval<=0.05 are rotated by acrophase

%% Output -----
% smoothedRotatedMatrix: equivalent size to matrix, each column of matrix 
% has been rotated by corresponding acrophase subject to pvalue significance


t=[]; 
rotated=[];
subtracted_acro = zeros(width(matrix),1);


%% Generate Array of Acrophases to be subtracted from matrix

for q = 1:length(subtracted_acro)
    if all(isnan(matrix(:,q)))
        continue
    elseif pval(q) >0.05
        continue
    else
        subtracted_acro(q) = acrophase(q);
    end
end

%% Rotate matrix indices to align acrophases
t=repmat((0:2*pi/144:2*pi*143/144)',[1,size(matrix,2)]);
t=t-subtracted_acro'-pi;
while any(t<0,'all')
    t(t<0)=t(t<0)+2*pi;
end
[~,sort_unrotated]=sort(t,'ascend');

for j=1:size(matrix,2)
    rotated(:,j)=matrix(sort_unrotated(:,j),j);
end

%% Gaussian Smooth Each Day
if smooth
    smoothedRotatedMatrix = zeros(size(rotated));
    for m = 1:width(rotated)
        day = rotated(:,m);
        smoothedRotatedMatrix(:,m) = smoothdata(day,'gaussian');
    end
else
    smoothedRotatedMatrix = rotated;
end
        
end