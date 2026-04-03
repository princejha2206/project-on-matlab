%% =========================================================
%  companding_analysis.m
%  Supplementary script: SQNR vs Input Amplitude sweep.
%  Shows the key advantage of companding for weak signals.
%  Run AFTER companding_main.m (shares same helper functions).
%% =========================================================

clear; clc;

mu     = 255;
A      = 87.6;
N_bits = 8;
Fs     = 8000;
t      = (0:1/Fs:0.5-1/Fs)';        % 0.5 s

% Amplitude levels to sweep (as fraction of full scale)
amp_levels = logspace(-3, 0, 60);    % 0.001 → 1.0 (log scale)

sqnr_plain_amp = zeros(size(amp_levels));
sqnr_mu_amp    = zeros(size(amp_levels));
sqnr_a_amp     = zeros(size(amp_levels));

fprintf('Running amplitude sweep (%d points)...\n', numel(amp_levels));

for k = 1:numel(amp_levels)
    amp = amp_levels(k);
    x   = amp * sin(2*pi*1000*t);     % 1 kHz sine at amplitude amp

    % Compression
    xc_mu = mulaw_compress(x, mu);
    xc_a  = alaw_compress(x, A);

    % Quantise
    xq_p  = uniform_quantise(x,     N_bits);
    xq_mc = uniform_quantise(xc_mu, N_bits);
    xq_ac = uniform_quantise(xc_a,  N_bits);

    % Expand
    xr_mu = mulaw_expand(xq_mc, mu);
    xr_a  = alaw_expand(xq_ac,  A);

    % SQNR
    sqnr_plain_amp(k) = calc_sqnr(x, xq_p);
    sqnr_mu_amp(k)    = calc_sqnr(x, xr_mu);
    sqnr_a_amp(k)     = calc_sqnr(x, xr_a);
end

%% ── Plot ──────────────────────────────────────────────────
figure('Name','SQNR vs Input Amplitude','NumberTitle','off', ...
       'Color','w','Position',[100 100 800 480]);

amp_dB = 20*log10(amp_levels);   % convert amplitude to dBFS

plot(amp_dB, sqnr_plain_amp, 'k-',  'LineWidth',2, 'DisplayName','Plain PCM'); hold on
plot(amp_dB, sqnr_mu_amp,    'b-',  'LineWidth',2, 'DisplayName','μ-Law');
plot(amp_dB, sqnr_a_amp,     'r--', 'LineWidth',2, 'DisplayName','A-Law');
grid on; legend('Location','northwest','FontSize',12)
xlabel('Input Amplitude (dBFS)', 'FontSize',13)
ylabel('SQNR (dB)',              'FontSize',13)
title(sprintf('SQNR vs Input Level  (%d-bit, 1 kHz sine)', N_bits), ...
      'FontSize',15, 'FontWeight','bold')
xlim([-60 0])

% ── Print summary table ────────────────────────────────────
fprintf('\n%-12s  %-12s  %-12s  %-12s\n','Amp (dBFS)','Plain (dB)','μ-Law (dB)','A-Law (dB)');
fprintf('%s\n', repmat('-',1,52));
sample_amps = [-40, -30, -20, -10, -6, 0];
for sa = sample_amps
    [~, idx] = min(abs(amp_dB - sa));
    fprintf('%-12.0f  %-12.2f  %-12.2f  %-12.2f\n', ...
        sa, sqnr_plain_amp(idx), sqnr_mu_amp(idx), sqnr_a_amp(idx));
end

fprintf('\nKey insight: At low amplitudes, companding maintains SQNR\n')
fprintf('while plain PCM degrades rapidly.\n')
