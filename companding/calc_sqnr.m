function sqnr_dB = calc_sqnr(x_orig, x_recon)
%CALC_SQNR  Signal-to-Quantisation-Noise Ratio in dB.
%
%   sqnr_dB = CALC_SQNR(x_orig, x_recon)
%
%   Formula:
%       SQNR = 10 * log10( E[x^2] / E[(x - xhat)^2] )
%
%   where E[.] denotes the sample mean (time-average estimate).

signal_power = mean(x_orig .^ 2);
noise_power  = mean((x_orig - x_recon) .^ 2);

if noise_power == 0
    sqnr_dB = Inf;
else
    sqnr_dB = 10 * log10(signal_power / noise_power);
end
end
