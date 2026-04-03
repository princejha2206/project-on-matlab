%% =========================================================
%  A-Law & μ-Law Companding — Main Script
%  Run this file to generate all results and figures.
%  Compatible with MATLAB R2018b or later (no extra toolbox).
%% =========================================================

clear; clc; close all;

%% ── 1. PARAMETERS ─────────────────────────────────────────
mu      = 255;      % μ-Law parameter (North America / Japan)
A       = 87.6;     % A-Law  parameter (Europe / ITU-T G.711)
N_bits  = 8;        % Number of quantisation bits (7-bit + 1 sign → 8-bit PCM)
Fs      = 8000;     % Sample rate (Hz) – telephony standard
t_dur   = 0.25;     % Signal duration (s)

fprintf('=== Companding Simulation  |  %d-bit PCM  |  Fs = %d Hz ===\n\n', N_bits, Fs);

%% ── 2. TEST SIGNAL ────────────────────────────────────────
%  Composite of three sinusoids at different amplitudes to
%  stress-test both low- and high-amplitude behaviour.
t   = (0 : 1/Fs : t_dur - 1/Fs)';   % time vector (column)
x   = 0.6*sin(2*pi*440*t) ...        % dominant tone (440 Hz)
    + 0.2*sin(2*pi*1200*t) ...       % mid component
    + 0.05*sin(2*pi*3400*t);         % low-amplitude component

x   = x / max(abs(x));              % normalise to [-1, +1]

%% ── 3. COMPRESSION ───────────────────────────────────────
x_mu_comp = mulaw_compress(x, mu);
x_a_comp  = alaw_compress(x, A);

%% ── 4. UNIFORM QUANTISATION ──────────────────────────────
levels = 2^N_bits;                   % 256 for 8-bit

x_quant_plain   = uniform_quantise(x,          N_bits);
x_quant_mu_comp = uniform_quantise(x_mu_comp,  N_bits);
x_quant_a_comp  = uniform_quantise(x_a_comp,   N_bits);

%% ── 5. EXPANSION (decode) ────────────────────────────────
x_mu_out = mulaw_expand(x_quant_mu_comp, mu);
x_a_out  = alaw_expand(x_quant_a_comp,  A);

%% ── 6. SQNR CALCULATION ──────────────────────────────────
sqnr_plain = calc_sqnr(x, x_quant_plain);
sqnr_mu    = calc_sqnr(x, x_mu_out);
sqnr_a     = calc_sqnr(x, x_a_out);

fprintf('SQNR Results (%d-bit quantisation):\n', N_bits);
fprintf('  Plain uniform PCM : %6.2f dB\n', sqnr_plain);
fprintf('  μ-Law companding  : %6.2f dB\n', sqnr_mu);
fprintf('  A-Law companding  : %6.2f dB\n\n', sqnr_a);

%% ── 7. SQNR vs NUMBER OF BITS ────────────────────────────
bits_range = 4:12;
sq_plain_v = zeros(size(bits_range));
sq_mu_v    = zeros(size(bits_range));
sq_a_v     = zeros(size(bits_range));

for k = 1:numel(bits_range)
    b = bits_range(k);
    xq_p  = uniform_quantise(x,           b);
    xq_mc = uniform_quantise(x_mu_comp,   b);
    xq_ac = uniform_quantise(x_a_comp,    b);
    sq_plain_v(k) = calc_sqnr(x, xq_p);
    sq_mu_v(k)    = calc_sqnr(x, mulaw_expand(xq_mc, mu));
    sq_a_v(k)     = calc_sqnr(x, alaw_expand(xq_ac, A));
end

%% ── 8. FIGURES ───────────────────────────────────────────

% ── Figure 1 : Companding Curves ─────────────────────────
figure('Name','Companding Curves','NumberTitle','off','Color','w', ...
       'Position',[50 500 900 400]);
xc = linspace(-1, 1, 1000)';

subplot(1,2,1)
plot(xc, mulaw_compress(xc,mu), 'b-', 'LineWidth',2); hold on
plot(xc, xc, 'k--', 'LineWidth',1);
grid on; axis square
title(sprintf('\\mu-Law Compression  (\\mu=%d)', mu), 'FontSize',13)
xlabel('Normalised Input x'); ylabel('Compressed Output y')
legend('μ-Law','Linear','Location','northwest')

subplot(1,2,2)
plot(xc, alaw_compress(xc,A), 'r-', 'LineWidth',2); hold on
plot(xc, xc, 'k--', 'LineWidth',1);
grid on; axis square
title(sprintf('A-Law Compression  (A=%.1f)', A), 'FontSize',13)
xlabel('Normalised Input x'); ylabel('Compressed Output y')
legend('A-Law','Linear','Location','northwest')
sgtitle('Companding Transfer Curves', 'FontSize',15,'FontWeight','bold')

% ── Figure 2 : Time-domain comparison (first 200 samples) ─
n_show = 200;
figure('Name','Time-Domain Signals','NumberTitle','off','Color','w', ...
       'Position',[50 80 1100 600]);

subplot(4,1,1)
plot(t(1:n_show), x(1:n_show), 'k', 'LineWidth',1.2)
title('Original Signal','FontSize',12); ylabel('Amplitude')
ylim([-1.2 1.2]); grid on

subplot(4,1,2)
plot(t(1:n_show), x_quant_plain(1:n_show), 'Color',[0.4 0.4 0.4],'LineWidth',1.2)
title(sprintf('Plain Uniform PCM  (SQNR = %.2f dB)', sqnr_plain),'FontSize',12)
ylabel('Amplitude'); ylim([-1.2 1.2]); grid on

subplot(4,1,3)
plot(t(1:n_show), x_mu_out(1:n_show), 'b', 'LineWidth',1.2)
title(sprintf('\\mu-Law Companding  (SQNR = %.2f dB)', sqnr_mu),'FontSize',12)
ylabel('Amplitude'); ylim([-1.2 1.2]); grid on

subplot(4,1,4)
plot(t(1:n_show), x_a_out(1:n_show), 'r', 'LineWidth',1.2)
title(sprintf('A-Law Companding  (SQNR = %.2f dB)', sqnr_a),'FontSize',12)
ylabel('Amplitude'); xlabel('Time (s)'); ylim([-1.2 1.2]); grid on

sgtitle('Time-Domain Signal Comparison (first 200 samples)', ...
        'FontSize',15,'FontWeight','bold')

% ── Figure 3 : Quantisation Error ────────────────────────
figure('Name','Quantisation Error','NumberTitle','off','Color','w', ...
       'Position',[980 500 900 400]);

e_plain = x - x_quant_plain;
e_mu    = x - x_mu_out;
e_a     = x - x_a_out;

subplot(1,3,1)
histogram(e_plain, 50, 'FaceColor',[0.5 0.5 0.5])
title('Plain PCM Error','FontSize',11); xlabel('Error'); ylabel('Count'); grid on

subplot(1,3,2)
histogram(e_mu, 50, 'FaceColor','b')
title('μ-Law Error','FontSize',11); xlabel('Error'); grid on

subplot(1,3,3)
histogram(e_a, 50, 'FaceColor','r')
title('A-Law Error','FontSize',11); xlabel('Error'); grid on

sgtitle('Quantisation Error Distribution', 'FontSize',14,'FontWeight','bold')

% ── Figure 4 : SQNR vs Bits ───────────────────────────────
figure('Name','SQNR vs Bits','NumberTitle','off','Color','w', ...
       'Position',[980 80 700 450]);
plot(bits_range, sq_plain_v, 'k-o','LineWidth',2,'MarkerSize',7,'DisplayName','Plain PCM'); hold on
plot(bits_range, sq_mu_v,    'b-s','LineWidth',2,'MarkerSize',7,'DisplayName','μ-Law'); 
plot(bits_range, sq_a_v,     'r-^','LineWidth',2,'MarkerSize',7,'DisplayName','A-Law');
grid on; legend('Location','northwest','FontSize',11)
xlabel('Number of Bits (N)','FontSize',12)
ylabel('SQNR (dB)','FontSize',12)
title('SQNR vs. Number of Quantisation Bits','FontSize',14,'FontWeight','bold')
xlim([bits_range(1) bits_range(end)])

% ── Figure 5 : Low-Amplitude Detail ──────────────────────
%  Zoom on region |x| < 0.1 to show companding advantage
figure('Name','Low-Amplitude Detail','NumberTitle','off','Color','w', ...
       'Position',[50 80 700 400]);
idx = abs(x) < 0.1;
if sum(idx) > 5
    ts = t(idx); 
    plot(ts, x(idx),            'k',  'LineWidth',1.5,'DisplayName','Original'); hold on
    plot(ts, x_quant_plain(idx),'--', 'Color',[0.5 0.5 0.5],'LineWidth',1.5,'DisplayName','Plain PCM')
    plot(ts, x_mu_out(idx),     'b:', 'LineWidth',2,  'DisplayName','μ-Law')
    plot(ts, x_a_out(idx),      'r-.','LineWidth',2,  'DisplayName','A-Law')
    grid on; legend('FontSize',11)
    xlabel('Time (s)'); ylabel('Amplitude')
    title('Low-Amplitude Detail  (|x| < 0.1)', 'FontSize',14,'FontWeight','bold')
else
    close   % skip if not enough low-amplitude samples
end

fprintf('All figures generated successfully.\n')
fprintf('Run  companding_analysis.m  for additional bit-depth sweep tables.\n')
