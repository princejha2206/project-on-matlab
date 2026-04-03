function y = mulaw_compress(x, mu)
%MULAW_COMPRESS  Apply μ-Law compression to input signal x.
%
%   y = MULAW_COMPRESS(x, mu)
%
%   Inputs:
%       x   – normalised input signal, values in [-1, +1]
%       mu  – μ-Law parameter (default 255 for North America / Japan)
%
%   Output:
%       y   – compressed signal, values in [-1, +1]
%
%   Formula (ITU-T G.711 / CCITT):
%       y = sign(x) * log(1 + mu*|x|) / log(1 + mu)
%
%   Reference: Haykin, "Communication Systems", 4th ed., §5.3

if nargin < 2
    mu = 255;
end

% Clamp input to valid range (numerical safety)
x = max(-1, min(1, x));

y = sign(x) .* log(1 + mu .* abs(x)) ./ log(1 + mu);
end
