%==========================================================================
% QUICK START GUIDE
%==========================================================================
% Audio Modulation & Quantization Analysis Toolkit
%
% This guide will get you up and running in 5 minutes
%
%==========================================================================

% =========================================================================
% INSTALLATION & SETUP
% =========================================================================

%% Step 1: Download and organize files
% 
% Required files (all should be in the same directory):
%   ✓ audioQuantizer.m       - Quantization engine
%   ✓ pcmCoder.m             - PCM encoder/decoder
%   ✓ dpcmCoder.m            - DPCM encoder/decoder
%   ✓ deltaModCoder.m        - Delta modulation encoder/decoder
%   ✓ sqnrCalculator.m       - Quality metrics calculator
%   ✓ main_GUI.m             - Interactive GUI application
%   ✓ example_script.m       - Comprehensive examples
%   ✓ README.md              - Theory and documentation
%   ✓ QUICKSTART.m           - This file

% =========================================================================
% QUICKEST START: Interactive GUI
% =========================================================================

%% Option 1: Launch GUI (30 seconds)
%
% In MATLAB Command Window:
%
%   >> main_GUI
%
% The GUI provides:
%   - Load WAV files or generate test signals
%   - Real-time parameter adjustment
%   - Live visualization
%   - Quality metrics display
%   - Export results
%
% No coding required!

% =========================================================================
% PROGRAMMATIC APPROACH: Code Examples
% =========================================================================

%% Option 2: Quick 5-Line Example
%
% Generate a test signal and encode it:

% 1. Generate signal
t = linspace(0, 1, 8000);
signal = sin(2*pi*1000*t)';

% 2. Apply PCM encoding
[~, decoded_pcm, ~, metrics] = pcmCoder.encode(signal, 8, 'uniform');

% 3. Calculate quality
sqnr_value = sqnrCalculator.calculateSQNR(signal, decoded_pcm);

% 4. Display result
fprintf('SQNR: %.2f dB\n', sqnr_value);

% 5. Visualize
figure;
plot(signal(1:200), 'b-', 'LineWidth', 2); hold on;
plot(decoded_pcm(1:200), 'r.', 'MarkerSize', 6);
legend('Original', 'PCM');
xlabel('Sample'); ylabel('Amplitude');
title('8-bit PCM Encoding');
grid on;

%% Example 2: Load Your Own WAV File

% Load audio file
[signal, fs] = audioread('your_audio_file.wav');

% Normalize
signal = signal / max(abs(signal));

% Encode with different methods
[~, pcm_out, ~, pcm_metrics] = pcmCoder.encode(signal, 8, 'uniform', fs);
[~, dpcm_out, ~, dpcm_metrics] = dpcmCoder.encode(signal, 8, 0.95, 'uniform', 1);

% Compare
fprintf('PCM SQNR:  %.2f dB\n', pcm_metrics.sqnr);
fprintf('DPCM SQNR: %.2f dB (improvement: %.2f dB)\n', ...
    dpcm_metrics.sqnr, dpcm_metrics.sqnr_improvement);

% Play reconstructed audio (if Audio Toolbox available)
% sound(pcm_out, fs);

%% Example 3: Bit Depth Comparison

% Test different bit depths
bitDepths = [4, 6, 8, 10, 12, 14, 16];
sqnr_results = [];

for bd = bitDepths
    [~, decoded, ~, metrics] = pcmCoder.encode(signal, bd, 'uniform');
    sqnr_results = [sqnr_results; metrics.sqnr];
end

% Plot
figure;
plot(bitDepths, sqnr_results, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Bit Depth'); ylabel('SQNR (dB)');
title('PCM Quality vs Bit Depth');
grid on;

% Each bit adds ~6 dB SQNR (verify: sqnr_results should increase ~6 dB/bit)

%% Example 4: Compare All Three Codecs

% Use same signal
signal_short = signal(1:4000);

% Encode
[~, pcm, ~, m_pcm] = pcmCoder.encode(signal_short, 8, 'uniform');
[~, dpcm, ~, m_dpcm] = dpcmCoder.encode(signal_short, 8, 0.95, 'uniform', 1);
[~, delta, ~, m_delta] = deltaModCoder.encodeFixed(signal_short, 0.1);

% Visualize time domain
figure('Position', [100 100 1200 400]);

subplot(1,3,1);
plot(1:200, signal_short(1:200), 'b-', 'LineWidth', 1.5);
hold on;
plot(1:200, pcm(1:200), 'r.', 'MarkerSize', 4);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('PCM (SQNR: %.2f dB)', m_pcm.sqnr));
legend('Original', 'PCM');
grid on;

subplot(1,3,2);
plot(1:200, signal_short(1:200), 'b-', 'LineWidth', 1.5);
hold on;
plot(1:200, dpcm(1:200), 'g+', 'MarkerSize', 5);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('DPCM (SQNR: %.2f dB)', m_dpcm.sqnr));
legend('Original', 'DPCM');
grid on;

subplot(1,3,3);
plot(1:200, signal_short(1:200), 'b-', 'LineWidth', 1.5);
hold on;
plot(1:200, delta(1:200), 'ms', 'MarkerSize', 3);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('Delta (SQNR: %.2f dB)', m_delta.sqnr));
legend('Original', 'Delta');
grid on;

%% Example 5: Quantization Type Comparison

% Compare quantization methods
signal_test = sin(2*pi*1000*(0:1/8000:0.5)');

[q_uniform, ~] = audioQuantizer.quantize(signal_test, 8, 'uniform');
[q_alaw, ~] = audioQuantizer.quantize(signal_test, 8, 'alaw');
[q_mulaw, ~] = audioQuantizer.quantize(signal_test, 8, 'mulaw');

% Metrics
m_u = sqnrCalculator.calculateDetailedMetrics(signal_test, q_uniform);
m_a = sqnrCalculator.calculateDetailedMetrics(signal_test, q_alaw);
m_m = sqnrCalculator.calculateDetailedMetrics(signal_test, q_mulaw);

% Display comparison table
fprintf('\n8-Bit Quantization Comparison:\n');
fprintf('Type       | SQNR (dB) | RMS Error | Correlation\n');
fprintf('-----------|-----------|-----------|-------------\n');
fprintf('Uniform    | %9.2f | %9.6f | %11.4f\n', m_u.sqnr, m_u.rms_error, m_u.correlation);
fprintf('A-law      | %9.2f | %9.6f | %11.4f\n', m_a.sqnr, m_a.rms_error, m_a.correlation);
fprintf('µ-law      | %9.2f | %9.6f | %11.4f\n', m_m.sqnr, m_m.rms_error, m_m.correlation);

%% Example 6: Detailed Quality Metrics

% Get comprehensive metrics
metrics_full = sqnrCalculator.calculateDetailedMetrics(signal, pcm_out);

% Display
fprintf('\nComprehensive Quality Metrics:\n');
fprintf('==============================\n');
fprintf('SQNR (dB):           %.2f\n', metrics_full.sqnr);
fprintf('SNR (dB):            %.2f\n', metrics_full.snr);
fprintf('SINAD (dB):          %.2f\n', metrics_full.sinad);
fprintf('ENOB (bits):         %.2f\n', metrics_full.enob);
fprintf('THD (%%):              %.4f\n', metrics_full.thd);
fprintf('RMS Error:           %.8f\n', metrics_full.rms_error);
fprintf('Correlation:         %.6f\n', metrics_full.correlation);

%% Example 7: DPCM Predictor Optimization

% Find optimal predictor coefficient
alphas = 0.5:0.05:0.99;

for i = 1:length(alphas)
    [~, ~, ~, metrics_alpha(i)] = dpcmCoder.encode(signal_test, 8, alphas(i), 'uniform', 1);
end

% Plot
figure;
plot(alphas, [metrics_alpha.sqnr], 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
[max_sqnr, idx_max] = max([metrics_alpha.sqnr]);
hold on;
plot(alphas(idx_max), max_sqnr, 'r*', 'MarkerSize', 15);
xlabel('Predictor Coefficient (α)');
ylabel('SQNR (dB)');
title('DPCM Performance vs Predictor Coefficient');
text(alphas(idx_max)+0.01, max_sqnr+0.2, ...
    sprintf('Optimal: α = %.2f\nSQNR = %.2f dB', alphas(idx_max), max_sqnr), ...
    'FontSize', 10, 'BackgroundColor', 'yellow');
grid on;

%% Example 8: DPCM Adaptive

% Adaptive DPCM with frame-based processing
[encoded_adp, decoded_adp, alphas_adp] = dpcmCoder.encodeAdaptive(signal_test, 8, 160);

% Show how alpha varies
figure;
subplot(2,1,1);
plot(alphas_adp, 'b-', 'LineWidth', 1.5);
xlabel('Frame'); ylabel('Predictor Coefficient (α)');
title('Adaptive DPCM - Frame-based Predictor Variation');
grid on;

subplot(2,1,2);
t_plot = 1:min(500, length(signal_test));
plot(t_plot, signal_test(t_plot), 'b-', 'LineWidth', 1.5);
hold on;
plot(t_plot, decoded_adp(t_plot), 'r--', 'LineWidth', 1);
xlabel('Sample'); ylabel('Amplitude');
title('Adaptive DPCM Reconstruction');
legend('Original', 'Decoded');
grid on;

%% Example 9: Delta Modulation Step Size Analysis

% Analyze impact of step size
deltaStepSizes = [0.05, 0.1, 0.15, 0.2, 0.3];

for i = 1:length(deltaStepSizes)
    [~, ~, ~, m_delta_ss(i)] = deltaModCoder.encodeFixed(signal_test, deltaStepSizes(i));
end

% Plot
figure;
subplot(1,2,1);
plot(deltaStepSizes, [m_delta_ss.sqnr], 'go-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Step Size (Δ)');
ylabel('SQNR (dB)');
title('Delta Modulation - SQNR vs Step Size');
grid on;

subplot(1,2,2);
slope_overload = [[m_delta_ss.slope_overload_risk]];
bar(slope_overload, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'black');
set(gca, 'XTickLabel', num2str(deltaStepSizes'));
xlabel('Step Size (Δ)');
ylabel('Slope Overload Risk');
title('Slope Overload Analysis');
grid on;

%% Example 10: Run Full Example Script

% Run the comprehensive example (requires ~30 seconds)
% Uncomment the next line:
% example_script

% =========================================================================
% COMMON OPERATIONS REFERENCE
% =========================================================================

%% Quick Reference: Common Tasks

% Task 1: Encode signal with PCM
% [~, decoded, bitstream, metrics] = pcmCoder.encode(signal, 8, 'uniform');

% Task 2: Encode signal with DPCM
% [~, decoded, error, metrics] = dpcmCoder.encode(signal, 8, 0.95, 'uniform', 1);

% Task 3: Encode signal with Delta Modulation
% [bits, decoded, estimate, metrics] = deltaModCoder.encodeFixed(signal, 0.1);

% Task 4: Calculate SQNR
% sqnr_db = sqnrCalculator.calculateSQNR(original, reconstructed);

% Task 5: Get detailed metrics
% metrics = sqnrCalculator.calculateDetailedMetrics(original, reconstructed, fs);

% Task 6: Compare multiple codecs
% metrics_list = {m_pcm, m_dpcm, m_delta};
% labels = {'PCM', 'DPCM', 'Delta'};
% sqnrCalculator.compareMetrics(metrics_list, labels);

% Task 7: Visualize waveforms
% pcmCoder.plotComparison(signal, decoded, bitDepth, quantType);

% Task 8: Frequency analysis
% [snr_spectrum, freq_bins] = pcmCoder.frequencyAnalysis(original, reconstructed, fs);

% =========================================================================
% TROUBLESHOOTING
% =========================================================================

%% Common Issues & Solutions

% Q: "Undefined function 'pcmCoder'" error
% A: Make sure all .m files are in the current directory or on MATLAB path
%    >> addpath(pwd);

% Q: GUI not launching
% A: Make sure you're using MATLAB R2021a or later
%    >> verLessThan('matlab', '9.10') % Returns true if older than R2021a

% Q: Error with audioread()
% A: You may not have the Audio Toolbox
%    Use generated signals instead, or use audioinfo() to check WAV file

% Q: Results seem incorrect
% A: Check signal normalization - input should be in [-1, 1] range
%    >> signal = signal / max(abs(signal));

% Q: DPCM not showing improvement
% A: Check signal correlation - prediction helps correlated signals
%    Use multi-tone or complex signals, not random noise

% Q: Delta modulation has too much noise
% A: Adjust step size Δ - try values between 0.1 and 0.2
%    Check for slope overload (bit patterns all same)

% =========================================================================
% PARAMETERS GUIDE
% =========================================================================

%% Parameter Settings

% BIT DEPTH
%   1-4:    Very low quality, compression only
%   8:      Telephony standard (64 kbps @ 8 kHz)
%   12:     Adequate for moderate quality
%   16:     CD quality
%   24-32:  Professional audio

% QUANTIZATION TYPE
%   'uniform': Simple, best for uniform signal distribution
%   'alaw':    ITU-G.711, European standard, better for speech
%   'mulaw':   ITU-G.711, North American standard, better for speech

% DPCM PREDICTOR ALPHA (α)
%   0.5:   Conservative, works well for non-stationary signals
%   0.75:  Good general-purpose
%   0.95:  Optimal for speech and music (default)
%   0.99:  Best for highly correlated signals

% DELTA MODULATION STEP SIZE (Δ)
%   0.05:  Small, low distortion but slope overload risk
%   0.1:   Standard value, good balance
%   0.2:   Larger, handles faster changes, more granular noise
%   0.5:   Very large, may miss signal details

% =========================================================================
% NEXT STEPS
% =========================================================================

% 1. Launch the interactive GUI for exploration
%    >> main_GUI

% 2. Run the comprehensive example script
%    >> example_script

% 3. Process your own WAV files
%    >> [sig, fs] = audioread('my_audio.wav');
%    >> main_GUI

% 4. Read the full README.md for theory and detailed documentation

% 5. Explore individual codec implementations:
%    >> edit pcmCoder.m      % Study PCM implementation
%    >> edit dpcmCoder.m     % Study DPCM implementation
%    >> edit deltaModCoder.m % Study Delta Modulation

% =========================================================================
% SUPPORT & DOCUMENTATION
% =========================================================================

% For theory and detailed information, see README.md

% Each .m file contains:
%   - Detailed comments and documentation
%   - Mathematical background
%   - Usage examples
%   - Implementation notes

% Help with specific functions:
%   >> help pcmCoder.encode
%   >> help dpcmCoder.encode
%   >> help deltaModCoder.encodeFixed
%   >> help sqnrCalculator.calculateSQNR

%==========================================================================
% END OF QUICK START GUIDE
%==========================================================================
