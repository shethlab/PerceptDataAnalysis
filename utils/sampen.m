function [Samp, A, B] = SampEn(Sig, varargin)
% SampEn  estimates the sample entropy of a univariate data sequence.
%
%   [Samp, A, B] = SampEn(Sig) 
% 
%   Returns the sample entropy estimates (``Samp``) and the number of matched state 
%   vectors (``m: B``, ``m+1: A``) for ``m`` = [0,1,2] estimated from the data 
%   sequence (``Sig``) using the default parameters: embedding dimension = 2, 
%   time delay = 1,  radius threshold = 0.2*SD(``Sig``), logarithm = natural
%
%   [Samp, A, B] = SampEn(Sig, name, value, ...)
% 
%   Returns the sample entropy estimates (``Samp``) for dimensions = [0,1,..., ``m``]
%   estimated from the data sequence (``Sig``) using the specified name/value pair
%   arguments:
% 
%       * ``m``     - Embedding Dimension, a positive integer
%       * ``tau``   - Time Delay, a positive integer
%       * ``r``     - Radius Distance Threshold, a positive scalar  
%       * ``Logx``  - Logarithm base, a positive scalar  
%
%   See also:
%       ApEn, FuzzEn, PermEn, CondEn, XSampEn, SampEn2D, MSEn.
%   
%   References:
%      [1] Joshua S Richman and J. Randall Moorman. 
%           "Physiological time-series analysis using approximate entropy
%           and sample entropy." 
%           American Journal of Physiology-Heart and Circulatory Physiology (2000).
% 
narginchk(1,9)
if size(Sig,1) == 1
    Sig = Sig';
end
Sig = squeeze(Sig);
p = inputParser;
Chk = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (mod(x,1)==0);
Chk2 = @(x) isscalar(x) && (x > 0);
addRequired(p,'Sig',@(x) isnumeric(x) && isvector(x) && (length(x) > 10));
addParameter(p,'m',2,Chk);
addParameter(p,'tau',1,Chk);
addParameter(p,'r',.2*std(Sig,1),Chk2);
addParameter(p,'Logx',exp(1),Chk2);
parse(p,Sig,varargin{:})
m = p.Results.m; tau = p.Results.tau; 
r = p.Results.r; Logx = p.Results.Logx; 
N = length(Sig);
Counter = (abs(Sig - Sig') <= r).*(triu(ones(N),1));
M = [m*ones(1,N-(m*tau)) repelem((m-1):-1:1,tau)];
A(1) = sum(sum(Counter));  B(1) = N*(N-1)/2;
for n = 1:N - tau
    ix = find(Counter(n,:)==1);
    for k = 1:M(n)
        ix(ix + (k*tau) > N) = [];  
        if isempty(ix)
            break
        end
        p1 = repmat(Sig(n:tau:n+(k*tau))',length(ix),1);
        p2 = Sig(ix+(0:tau:tau*k)')';        
        ix = ix(max(abs(p1 - p2),[],2) <= r);
        Counter(n, ix) = Counter(n, ix)+1;
    end
end
for k = 1:m
    A(k+1) = sum(sum(Counter>k));
    B(k+1) = sum(sum(Counter(:,1:N-(k*tau))>=k));
end
Samp = -log(A./B)/log(Logx);
end
%   Copyright 2021 Matthew W. Flood, EntropyHub
% 
%   Licensed under the Apache License, Version 2.0 (the "License");
%   you may not use this file except in compliance with the License.
%   You may obtain a copy of the License at
%
%        http://www.apache.org/licenses/LICENSE-2.0
%
%   Unless required by applicable law or agreed to in writing, software
%   distributed under the License is distributed on an "AS IS" BASIS,
%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%   See the License for the specific language governing permissions and
%   limitations under the License.
%
%   For Terms of Use see https://github.com/MattWillFlood/EntropyHub