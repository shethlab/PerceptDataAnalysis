%% Calculates the test statistic and p-values for a deLong test between two 
% ROCs using the wilcoxon test methods. Code has been adapted from 
% ailstairewj's auroc-matlab package (https://github.com/alistairewj/auroc-matlab).

function [thetaP,theta2,theta1] = wilcoxonConfidence(L, S, theta, alpha )

L_sz = size(L);
S_sz = size(S);
theta_sz = size(theta);

% Ensure thetas are a column vector
if theta_sz(1) == 1
    theta = theta'; % Transpose to column
else theta_sz(2) == 1
    % Do nothing, theta is a column vector
end

if S_sz(2) ~= L_sz(2) % Contrast column # is not equal to number of classifiers
    error('Dimension mismatch between contrast L and covariance S.');
end

LSL = L*S*L';
if L_sz(1) == 1 % One row
    % Compute using the normal distribution
    mu = abs(L*theta);
    sigma = sqrt(LSL);
    theta1 = mu/sigma;
    thetaP = normcdf(0,mu,sigma); 
    % 2-sided test, double the tails -> double the p-value
    if mu < 0
        thetaP = 2*(1 - thetaP);
    else
        thetaP = 2*thetaP;
    end
    theta2 = norminv([alpha/2,1-alpha/2],theta(L==1),sigma);
else
    % Calculate chi2 stat with DOF=rank(L*S*L');
    w_chi2 = theta'*L'*(inv(LSL))*L*theta;
    w_df = rank(LSL);
    thetaP = 1-chi2cdf(w_chi2,w_df);
    theta2 = w_chi2;
end

end