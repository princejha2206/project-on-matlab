function y = alaw_compress(x, A)
%ALAW_COMPRESS  Apply A-Law compression to input signal x.
%
%   y = ALAW_COMPRESS(x, A)
%
%   Inputs:
%       x   – normalised input signal, values in [-1, +1]
%       A   – A-Law parameter (default 87.6 per ITU-T G.711)
%
%   Output:
%       y   – compressed signal, values in [-1, +1]
%
%   Piecewise formula (ITU-T G.711):
%
%       For |x| <= 1/A :
%           y = sign(x) * A*|x| / (1 + ln A)
%
%       For 1/A < |x| <= 1 :
%           y = sign(x) * (1 + ln(A*|x|)) / (1 + ln A)
%
%   The two segments join continuously at |x| = 1/A.

if nargin < 2
    A = 87.6;
end

x = max(-1, min(1, x));   % clamp

ax  = abs(x);
lnA = log(A);              % natural log of A

y = zeros(size(x));

% Region 1 : |x| <= 1/A  (linear segment)
mask1 = ax <= 1/A;
y(mask1) = A .* ax(mask1) ./ (1 + lnA);

% Region 2 : 1/A < |x| <= 1  (logarithmic segment)
mask2 = ~mask1;
y(mask2) = (1 + log(A .* ax(mask2))) ./ (1 + lnA);

% Restore sign
y = sign(x) .* y;
end
