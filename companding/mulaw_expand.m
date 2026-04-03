function x = mulaw_expand(y, mu)
%MULAW_EXPAND  Apply μ-Law expansion (inverse of mulaw_compress).
%
%   x = MULAW_EXPAND(y, mu)
%
%   Inputs:
%       y   – compressed & quantised signal, values in [-1, +1]
%       mu  – μ-Law parameter (default 255)
%
%   Output:
%       x   – expanded (reconstructed) signal
%
%   Inverse formula:
%       x = sign(y) * (1/mu) * ((1+mu)^|y| - 1)

if nargin < 2
    mu = 255;
end

y = max(-1, min(1, y));

x = sign(y) .* (1/mu) .* ((1 + mu).^abs(y) - 1);
end
