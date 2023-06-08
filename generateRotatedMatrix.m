savepath = 'C:\Users\Owner\Desktop\Percept Runnig Circadian Data\SmoothedRotatedCirc.mat';

smoothedRotatedCircadianMatricesDecib = {};

for i = 1:5
    smoothedRotatedCircadianMatrices{i,1} = comb_LFP_logscaled{i,1};
    for j = 2:3
        smoothedRotatedCircadianMatrices{i,j} = smoothRotate(comb_LFP_logscaled{i,j},comb_acro{i,j-1},comb_p{i,j-1},0);
        
    end

end

%%save(savepath,'smoothedRotatedCircadianMatricesDecib','comb_days');


j = 4;
for j = 1:5
x = comb_days{j,1};
y = ema{j};
dx = (diff(x)); 
dxi = find(dx > 1);
try
xc = x(1:dxi(1));
yc = y(1:dxi(1));
for i = 1:length(find(dx>1))-1
    l = dx(dx>1);
    l = l(i);
    xnan = nan(1, l-1);                            % sNaNN Vector (Fill Missing Elements)
    dxi = find(dx > 1);   
% First Index Of Missing Elements
    xc = [xc xnan x(dxi(i)+1:dxi(i+1))];        % Replace Missing Elements With xxnanc Vector
    yc = [yc xnan y(dxi(i)+1:dxi(i+1))];    
end
catch
    xc = x;
    yc = y;
end

inds = find(abs(xc)<5);
figure
plot(xc(inds),yc(inds))
linkaxes
end