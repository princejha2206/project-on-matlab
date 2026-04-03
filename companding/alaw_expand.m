function x = alaw_expand(y, A)
%ALAW_EXPAND  Apply A-Law expansion (inverse of alaw_compress).
%
%   x = ALAW_EXPAND(y, A)
%
%   Inputs:
%       y   – compressed & quantised signal, values in [-1, +1]
%       A   – A-Law parameter (default 87.6)
%
%   Output:
%       x   – expanded (reconstructed) signal
%
%   Inverse piecewise formula:
%
%       For |y| <= A/(1 + ln A) :
%           x = sign(y) * |y| * (1 + ln A) / A
%
%       For A/(1 + ln A) < |y| <= 1 :
%           x = sign(y) * exp(|y|*(1+lnA) - 1) / A

if nargin < 2
    A = 87.6;
end

y = max(-1, min(1, y));

ay  = abs(y);
lnA = log(A);
thresh = A / (1 + lnA);

x = zeros(size(y));

% Region 1
mask1 = ay <= thresh / (1 + lnA);    % equivalent boundary in y
% Re-derive boundary: y_thresh = A*(1/A)/(1+lnA) = 1/(1+lnA)
y_thresh = 1 / (1 + lnA);
mask1 = ay <= y_thresh;

x(mask1) = ay(mask1) .* (1 + lnA) ./ A;

% Region 2
mask2 = ~mask1;
x(mask2) = exp(ay(mask2) .* (1 + lnA) - 1) ./ A;

x = sign(y) .* x;
end
