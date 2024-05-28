%% Calculates a Wilcoxon covariance matrix used in the deLong test for 
% comparing ROCs. Code has been adapted from ailstairewj's auroc-matlab 
% package (https://github.com/alistairewj/auroc-matlab).

function [S,S10,S01,V10,V01,theta] = wilcoxonCovariance(varargin)

if mod(length(varargin),2) ~= 0 % Wrong number of inputs
    error('Input requires matching prediction/target pairs');
elseif length(unique(cellfun(@length,varargin))) > 1 % Inputs are not same size
    error('Inputs not of the same size. Must be from the same data set.');
elseif length(varargin) == 2 && size(varargin{1},2) > 1
    % First input is matrix of predictions
    K = size(varargin{1},2);
    idx = varargin{2} == 1;
    X = varargin{1}(idx,:); m = size(X,1);
    Y = varargin{1}(~idx,:); n = size(Y,1);    
else % Proper input format
    % Parse first two inputs to get sizes of N and M
    idx = varargin{2} == 1;
    K = length(varargin)/2; % Number of prediction/target pairs
    X_temp = varargin{1}(idx); m = length(X_temp);
    Y_temp = varargin{1}(~idx); n = length(Y_temp);
    X = zeros(m,K); Y = zeros(n,K);
    X(:,1) = X_temp; Y(:,1) = Y_temp;
    for r = 2:1:K
        idx = varargin{2*r} == 1;
        X(:,r) = varargin{2*r-1}(idx);
        Y(:,r) = varargin{2*r-1}(~idx);
    end
    clear X_temp Y_temp idx;
end

% % % -------------- THETA, V10, V01 -------------- % % %
% Using matrices X and Y, calculate estimated Wilcoxon statistic (theta)
% Also Calculate the mxK and nxK V10 and V01 matrices
% theta=wilcoxonEXACTXY(X,Y); % = AUROC

N1 = size(Y);
N2 = size(X);

if N1(2) ~= N2(2) % Matrices do not have predictions for both target values
    error('X and Y should have the same number of columns.\n');
end

theta = zeros(1,K);
V10 = zeros(m,K); 
V01 = zeros(n,K);

for r = 1:K % For each X/Y column pair
    % compare 0s to 1s
    for i = 1:m
        phi1 = sum(gt(X(i,r),Y(:,r))); % Xi>Y
        phi2 = sum(eq(X(i,r),Y(:,r))); % Xi=Y
        V10(i,r) = (phi1 + phi2*0.5)/n;
        theta(r) = theta(r) + phi1 + phi2*0.5;
    end
    theta(r) = theta(r)/(n*m);
    for j = 1:n
        phi1 = gt(X(:,r),Y(j,r)); % X>Yj
        phi2 = eq(X(:,r),Y(j,r)); % X=Yj
        V01(j,r) = (sum(phi1)+sum(phi2)*0.5)/m;
    end
end

%  Calculate S01 and S10, covariance matrices of V01 and V10
S01 = (1/(n-1))*((V01'*V01) - n*(theta'*theta));
S10 = (1/(m-1))*((V10'*V10) - m*(theta'*theta));

% Combine for S, covariance matrix of theta
S= (1/m)*S10 + (1/n)*S01;

end