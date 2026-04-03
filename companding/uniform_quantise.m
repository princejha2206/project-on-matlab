function xq = uniform_quantise(x, N_bits)
%UNIFORM_QUANTISE  Mid-tread uniform quantiser.
%
%   xq = UNIFORM_QUANTISE(x, N_bits)
%
%   Inputs:
%       x      – input signal, values in [-1, +1]
%       N_bits – number of quantisation bits (e.g. 8 → 256 levels)
%
%   Output:
%       xq     – quantised signal (same range as input)
%
%   Implementation:
%       Step size  Δ = 2 / 2^N_bits
%       Index       = floor((x + 1) / Δ)   then clamp to [0, L-1]
%       Reconstruct = (index + 0.5) * Δ - 1   (mid-tread centroid)

L     = 2^N_bits;          % number of levels
delta = 2 / L;             % step size (input range = [-1,+1])

% Clamp then quantise
x = max(-1, min(1 - 1e-12, x));           % exclude upper boundary
idx = floor((x + 1) ./ delta);            % integer index [0, L-1]
idx = max(0, min(L-1, idx));              % safety clamp

xq  = (idx + 0.5) .* delta - 1;          % mid-tread reconstruction
end


function sqnr_dB = calc_sqnr(x_orig, x_recon)
%CALC_SQNR  Signal-to-Quantisation-Noise Ratio in dB.
%
%   sqnr_dB = CALC_SQNR(x_orig, x_recon)
%
%   SQNR = 10*log10( E[x^2] / E[(x - x_recon)^2] )

signal_power = mean(x_orig .^ 2);
noise_power  = mean((x_orig - x_recon) .^ 2);

if noise_power == 0
    sqnr_dB = Inf;
else
    sqnr_dB = 10 * log10(signal_power / noise_power);
end
end
