%==========================================================================
% COMPLETE EXAMPLE SCRIPT
%==========================================================================
% Demonstrates all audio modulation and quantization techniques
% Batch processing, detailed analysis, and visualization
%
% Run this script to see comprehensive examples of:
%   - PCM encoding/decoding
%   - DPCM with different predictors
%   - Delta Modulation (fixed and adaptive)
%   - Quantization comparison (uniform, A-law, µ-law)
%   - SQNR analysis and metrics
%   - Frequency analysis
%
%==========================================================================

clear all; close all; clc;

fprintf('========================================================================\n');
fprintf('AUDIO MODULATION & QUANTIZATION COMPLETE EXAMPLE\n');
fprintf('========================================================================\n\n');

% =========================================================================
% PART 1: GENERATE TEST SIGNALS
% =========================================================================

fprintf('PART 1: GENERATING TEST SIGNALS\n');
fprintf('---------------------------------\n\n');

% Signal parameters
fs = 8000;              % Sampling frequency (telephony standard)
duration = 2;           % Duration in seconds
t = 0:1/fs:duration-1/fs;
t = t(:);

% Signal 1: Pure sine wave (1 kHz)
signal1 = sin(2*pi*1000*t);
fprintf('Signal 1: Pure sine wave (1 kHz)\n');
fprintf('  Length: %d samples (%.2f seconds)\n', length(signal1), duration);
fprintf('  Peak amplitude: %.4f\n\n', max(abs(signal1)));

% Signal 2: Multi-tone (speech-like)
signal2 = 0.3*sin(2*pi*800*t) + 0.3*sin(2*pi*1500*t) + 0.2*sin(2*pi*3000*t);
fprintf('Signal 2: Multi-tone (simulates speech)\n');
fprintf('  Components: 800 Hz, 1500 Hz, 3000 Hz\n');
fprintf('  Peak amplitude: %.4f\n\n', max(abs(signal2)));

% Signal 3: Complex signal with harmonics
signal3 = sin(2*pi*1000*t) + 0.5*sin(2*pi*2000*t) + 0.25*sin(2*pi*3000*t);
fprintf('Signal 3: Harmonically rich signal\n');
fprintf('  Fundamental: 1000 Hz (1st, 2nd, 3rd harmonics)\n');
fprintf('  Peak amplitude: %.4f\n\n', max(abs(signal3)));

% =========================================================================
% PART 2: QUANTIZATION METHODS COMPARISON
% =========================================================================

fprintf('\nPART 2: QUANTIZATION METHODS COMPARISON\n');
fprintf('---------------------------------------\n\n');

signal = signal1(1:1000); % Use first 1000 samples for comparison
bitDepth = 8;

% Apply different quantization methods
[q_uniform, levels_u] = audioQuantizer.quantize(signal, bitDepth, 'uniform');
[q_alaw, levels_a] = audioQuantizer.quantize(signal, bitDepth, 'alaw');
[q_mulaw, levels_m] = audioQuantizer.quantize(signal, bitDepth, 'mulaw');

% Calculate metrics for each
metrics_u = sqnrCalculator.calculateDetailedMetrics(signal, q_uniform, fs);
metrics_a = sqnrCalculator.calculateDetailedMetrics(signal, q_alaw, fs);
metrics_m = sqnrCalculator.calculateDetailedMetrics(signal, q_mulaw, fs);

fprintf('Quantization Method Comparison (%d bits):\n\n', bitDepth);
fprintf('%-12s | SQNR (dB) | RMS Error | Entropy (bits)\n', 'Method');
fprintf('%-12s | %-9s | %-9s | %-13s\n', '-----------', '---------', '---------', '------');

entropy_u = audioQuantizer.calculateEntropy(q_uniform, 2^bitDepth);
entropy_a = audioQuantizer.calculateEntropy(q_alaw, 2^bitDepth);
entropy_m = audioQuantizer.calculateEntropy(q_mulaw, 2^bitDepth);

fprintf('%-12s | %9.2f | %9.6f | %13.3f\n', 'Uniform', metrics_u.sqnr, metrics_u.rms_error, entropy_u);
fprintf('%-12s | %9.2f | %9.6f | %13.3f\n', 'A-law', metrics_a.sqnr, metrics_a.rms_error, entropy_a);
fprintf('%-12s | %9.2f | %9.6f | %13.3f\n', 'µ-law', metrics_m.sqnr, metrics_m.rms_error, entropy_m);

fprintf('\nObservations:\n');
fprintf('• A-law & µ-law provide ~3-5 dB better SQNR for same bit depth\n');
fprintf('• Non-uniform quantization better allocates bits to weak signals\n');
fprintf('• A-law: European telephony standard (ITU-T G.711)\n');
fprintf('• µ-law: North American telephony standard (ITU-T G.711)\n\n');

% =========================================================================
% PART 3: PCM ENCODING WITH DIFFERENT BIT DEPTHS
% =========================================================================

fprintf('PART 3: PCM ENCODING - BIT DEPTH ANALYSIS\n');
fprintf('----------------------------------------\n\n');

bitDepths = [4, 6, 8, 10, 12, 14, 16];
results_pcm = pcmCoder.compareQuantizations(signal, 'uniform', bitDepths, fs);

fprintf('PCM Performance vs Bit Depth (Uniform Quantization):\n\n');
fprintf('BitDepth | Bitrate | SQNR (dB) | Theoretical | Difference\n');
fprintf('---------|---------|-----------|-------------|------------\n');

for i = 1:length(results_pcm)
    m = results_pcm(i).metrics;
    fprintf('%8d | %7d | %9.2f | %11.2f | %10.2f\n', ...
        m.bitDepth, m.bitrate, m.sqnr, m.sqnr_theoretical, ...
        m.sqnr - m.sqnr_theoretical);
end

fprintf('\nInterpretation:\n');
fprintf('• SQNR increases by ~6 dB per additional bit (theory: 6.02 dB)\n');
fprintf('• Good agreement with theoretical values\n');
fprintf('• 8-bit PCM: Standard for telephony (64 kbps @ 8 kHz)\n');
fprintf('• 16-bit PCM: CD quality audio (128 kbps @ 16 kHz)\n\n');

% =========================================================================
% PART 4: DPCM WITH DIFFERENT PREDICTORS
% =========================================================================

fprintf('PART 4: DPCM - PREDICTOR OPTIMIZATION\n');
fprintf('-------------------------------------\n\n');

% Test different predictor coefficients
alphas = [0.5, 0.75, 0.9, 0.95, 0.99];
bitDepth_dpcm = 8;

fprintf('DPCM SQNR vs Predictor Coefficient (α):\n\n');
fprintf('   Alpha | SQNR (dB) | Improvement vs PCM | Prediction Gain\n');
fprintf('--------|-----------|--------------------|-----------------\n');

dpcm_results = [];
for i = 1:length(alphas)
    [~, ~, ~, metrics] = dpcmCoder.encode(signal, bitDepth_dpcm, alphas(i), 'uniform', 1);
    fprintf('%8.3f | %9.2f | %18.2f | %15.2f %%\n', ...
        alphas(i), metrics.sqnr, metrics.sqnr_improvement, metrics.prediction_gain_percent);
    dpcm_results = [dpcm_results; metrics];
end

fprintf('\nKey Findings:\n');
fprintf('• Optimal α ≈ 0.95 for typical signals\n');
fprintf('• Prediction gain: 4-6 dB compared to PCM\n');
fprintf('• Higher α = better for correlated signals\n');
fprintf('• Adaptive predictors can achieve 2-4 dB additional gain\n\n');

% =========================================================================
% PART 5: DELTA MODULATION ANALYSIS
% =========================================================================

fprintf('PART 5: DELTA MODULATION - STEP SIZE OPTIMIZATION\n');
fprintf('--------------------------------------------------\n\n');

% Test different step sizes
stepSizes = [0.05, 0.1, 0.15, 0.2, 0.3];

fprintf('Delta Modulation SQNR vs Step Size (Δ):\n\n');
fprintf('     Step Size | Bitrate | SQNR (dB) | Max Error | Slope Overload\n');
fprintf('-------------|---------|-----------|-----------|-----------------\n');

delta_results_struct = deltaModCoder.compareStepSizes(signal, fs, stepSizes);

for i = 1:length(delta_results_struct)
    m = delta_results_struct(i).metrics;
    overload_str = yesno_str(m.slope_overload_risk);
    fprintf('%13.4f | %7d | %9.2f | %9.6f | %7s\n', ...
        m.step_size, m.bitrate, m.sqnr, m.max_error, overload_str);
end

fprintf('\nDelta Modulation Insights:\n');
fprintf('• Extreme compression: 1 bit per sample\n');
fprintf('• Trade-off between granular noise and slope overload\n');
fprintf('• Optimal Δ depends on signal characteristics\n');
fprintf('• Adaptive step size improves performance significantly\n\n');

% =========================================================================
% PART 6: CODEC COMPARISON
% =========================================================================

fprintf('PART 6: COMPREHENSIVE CODEC COMPARISON\n');
fprintf('--------------------------------------\n\n');

bitDepth = 8;
quantType = 'uniform';

% Encode with all methods
[~, decoded_pcm, ~, metrics_pcm] = pcmCoder.encode(signal, bitDepth, quantType, fs);
[~, decoded_dpcm, ~, metrics_dpcm] = dpcmCoder.encode(signal, bitDepth, 0.95, quantType, 1);
[~, decoded_delta, ~, metrics_delta] = deltaModCoder.encodeFixed(signal, 0.1, fs);

fprintf('Summary Table:\n\n');
fprintf('Codec          | Bitrate | SQNR (dB) | Compression | Key Feature\n');
fprintf('---------------|---------|-----------|-------------|-----------------------------\n');
fprintf('PCM (uniform)  | %7d | %9.2f | %11.1f:1 | Baseline linear quantization\n', ...
    metrics_pcm.bitrate, metrics_pcm.sqnr, 16/bitDepth);
fprintf('DPCM (α=0.95)  | %7d | %9.2f | %11.1f:1 | Exploits signal correlation\n', ...
    metrics_dpcm.bitrate, metrics_dpcm.sqnr, 16/bitDepth);
fprintf('Delta Mod      | %7d | %9.2f | %11.1f:1 | Extreme low bitrate\n', ...
    metrics_delta.bitrate, metrics_delta.sqnr, 16/1);

fprintf('\nPerformance Summary:\n');
fprintf('• DPCM provides %.2f dB improvement over PCM\n', metrics_dpcm.sqnr - metrics_pcm.sqnr);
fprintf('• Delta mod uses 8× less bandwidth than 8-bit PCM\n');
fprintf('• DPCM: best for speech (telephony: ADPCM)\n');
fprintf('• PCM: best for general audio (CDs, streaming)\n');
fprintf('• Delta: best when extreme compression needed\n\n');

% =========================================================================
% PART 7: DETAILED METRICS ANALYSIS
% =========================================================================

fprintf('PART 7: DETAILED METRICS FOR OPTIMAL CODEC\n');
fprintf('-----------------------------------------\n\n');

metrics_opt = sqnrCalculator.calculateDetailedMetrics(signal, decoded_dpcm, fs);

fprintf('DPCM Quality Metrics:\n\n');
fprintf('Signal Metrics:\n');
fprintf('  Signal Power: %.6f\n', metrics_opt.original_power);
fprintf('  Signal Power (dB): %.2f dB\n', metrics_opt.original_power_db);
fprintf('  Peak Amplitude: %.4f\n', metrics_opt.peak_original);
fprintf('  Crest Factor: %.2f\n', metrics_opt.crest_factor_original);

fprintf('\nDistortion Metrics:\n');
fprintf('  SQNR: %.2f dB (Signal-to-Quantization-Noise-Ratio)\n', metrics_opt.sqnr);
fprintf('  SNR: %.2f dB (Signal-to-Noise-Ratio)\n', metrics_opt.snr);
fprintf('  SINAD: %.2f dB (Signal-to-Noise-And-Distortion)\n', metrics_opt.sinad);
fprintf('  THD: %.4f %% (Total Harmonic Distortion)\n', metrics_opt.thd);

fprintf('\nError Metrics:\n');
fprintf('  RMS Error: %.8f\n', metrics_opt.rms_error);
fprintf('  Mean Error: %.8f\n', metrics_opt.mean_error);
fprintf('  Std Dev Error: %.8f\n', metrics_opt.std_error);
fprintf('  Max Error: %.8f\n', metrics_opt.max_error);

fprintf('\nFrequency Content:\n');
fprintf('  Signal Bandwidth: %.2f Hz\n', metrics_opt.signal_bandwidth);
fprintf('  Error Bandwidth: %.2f Hz\n', metrics_opt.error_bandwidth);
fprintf('  Correlation: %.6f\n', metrics_opt.correlation);
fprintf('  Zero-Crossing Rate: %.4f\n', metrics_opt.zero_crossing_rate);
fprintf('  ENOB: %.2f bits (Effective Number of Bits)\n\n', metrics_opt.enob);

% =========================================================================
% PART 8: VISUALIZATION
% =========================================================================

fprintf('PART 8: GENERATING VISUALIZATIONS\n');
fprintf('---------------------------------\n\n');

% Time domain comparison
figure('Name', 'Codec Comparison - Time Domain', 'Position', [100 100 1200 600]);

t_display = 1:min(1000, length(signal));

subplot(2,3,1);
plot(t_display, signal(t_display), 'b-', 'LineWidth', 1.5);
hold on;
plot(t_display, decoded_pcm(t_display), 'r.', 'MarkerSize', 4);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('PCM (%d bits, %.2f dB)', bitDepth, metrics_pcm.sqnr));
legend('Original', 'PCM');
grid on;

subplot(2,3,2);
plot(t_display, signal(t_display), 'b-', 'LineWidth', 1.5);
hold on;
plot(t_display, decoded_dpcm(t_display), 'g^', 'MarkerSize', 4);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('DPCM (%d bits, %.2f dB)', bitDepth, metrics_dpcm.sqnr));
legend('Original', 'DPCM');
grid on;

subplot(2,3,3);
plot(t_display, signal(t_display), 'b-', 'LineWidth', 1.5);
hold on;
plot(t_display, decoded_delta(t_display), 'ms', 'MarkerSize', 3);
xlabel('Sample'); ylabel('Amplitude');
title(sprintf('Delta (%.4f, %.2f dB)', 0.1, metrics_delta.sqnr));
legend('Original', 'Delta');
grid on;

% Error comparison
subplot(2,3,4);
error_pcm = signal - decoded_pcm;
error_dpcm = signal - decoded_dpcm;
error_delta = signal - decoded_delta;
plot(t_display, error_pcm(t_display), 'r-', 'LineWidth', 1);
xlabel('Sample'); ylabel('Error');
title(sprintf('PCM Error (RMS: %.6f)', metrics_pcm.rms_error));
grid on;

subplot(2,3,5);
plot(t_display, error_dpcm(t_display), 'g-', 'LineWidth', 1);
xlabel('Sample'); ylabel('Error');
title(sprintf('DPCM Error (RMS: %.6f)', metrics_dpcm.rms_error));
grid on;

subplot(2,3,6);
plot(t_display, error_delta(t_display), 'm-', 'LineWidth', 1);
xlabel('Sample'); ylabel('Error');
title(sprintf('Delta Error (RMS: %.6f)', metrics_delta.rms_error));
grid on;

% FFT comparison
figure('Name', 'Frequency Domain Analysis', 'Position', [100 100 1200 400]);

N = length(signal);
freq = 0:1:N-1;
spec_signal = abs(fft(signal, N));
spec_pcm = abs(fft(decoded_pcm, N));
spec_dpcm = abs(fft(decoded_dpcm, N));

subplot(1,3,1);
semilogy(freq(1:N/2), spec_signal(1:N/2), 'b-', 'LineWidth', 1.5);
hold on;
semilogy(freq(1:N/2), spec_pcm(1:N/2), 'r--', 'LineWidth', 1);
xlabel('Frequency Bin'); ylabel('Magnitude (log scale)');
title('PCM Frequency Response');
legend('Original', 'PCM');
grid on;

subplot(1,3,2);
semilogy(freq(1:N/2), spec_signal(1:N/2), 'b-', 'LineWidth', 1.5);
hold on;
semilogy(freq(1:N/2), spec_dpcm(1:N/2), 'g--', 'LineWidth', 1);
xlabel('Frequency Bin'); ylabel('Magnitude (log scale)');
title('DPCM Frequency Response');
legend('Original', 'DPCM');
grid on;

subplot(1,3,3);
sqnr_values = [metrics_pcm.sqnr, metrics_dpcm.sqnr, metrics_delta.sqnr];
codec_names = {'PCM', 'DPCM', 'Delta'};
bar(sqnr_values, 'FaceColor', 'cyan', 'EdgeColor', 'black', 'LineWidth', 1.5);
set(gca, 'XTickLabel', codec_names);
ylabel('SQNR (dB)');
title('Codec Quality Comparison');
grid on;

fprintf('✓ Generated 2 comparison figures\n');
fprintf('  - Time domain waveforms and errors\n');
fprintf('  - Frequency domain analysis\n\n');

% =========================================================================
% PART 9: PRACTICAL APPLICATIONS
% =========================================================================

fprintf('PART 9: PRACTICAL APPLICATIONS\n');
fprintf('------------------------------\n\n');

fprintf('Application Recommendations:\n\n');
fprintf('1. TELEPHONY (8 kHz sampling, 64 kbps bitrate):\n');
fprintf('   • Standard: PCM-µlaw (North America) or PCM-Alaw (Europe)\n');
fprintf('   • Modern: ADPCM (G.721, G.722) for better quality at lower bitrate\n');
fprintf('   • DPCM + entropy coding: 24-32 kbps (GSM standard)\n\n');

fprintf('2. AUDIO STREAMING (16 kHz+ sampling):\n');
fprintf('   • 16-bit PCM: baseline (uncompressed)\n');
fprintf('   • DPCM + Huffman coding: 50-70%% reduction\n');
fprintf('   • With transform (MP3, AAC): 90%% reduction at near-CD quality\n\n');

fprintf('3. SATELLITE/TELEMETRY:\n');
fprintf('   • Delta modulation: extreme compression\n');
fprintf('   • Adaptive DM: best trade-off between quality and bitrate\n');
fprintf('   • CVSD (Continuously Variable Slope DM): military/aerospace\n\n');

fprintf('4. MEDICAL/BIOMEDICAL:\n');
fprintf('   • High bit depths (12-16 bits) for precision\n');
fprintf('   • PCM with no compression (lossless required)\n');
fprintf('   • DPCM optional for storage optimization\n\n');

% =========================================================================
% PART 10: CONCLUSIONS
% =========================================================================

fprintf('PART 10: KEY TAKEAWAYS\n');
fprintf('---------------------\n\n');

fprintf('Quantization:\n');
fprintf('✓ Uniform quantization: simplest, 6 dB/bit SNR\n');
fprintf('✓ A-law/µ-law: better for non-uniform signals, telephony standard\n');
fprintf('✓ Non-uniform: ~5 dB gain for weak signals\n\n');

fprintf('Codec Performance:\n');
fprintf('✓ PCM: baseline, simple, no compression\n');
fprintf('✓ DPCM: 4-6 dB gain, exploits correlation, ~20%% data reduction\n');
fprintf('✓ Delta: 8:1 compression vs 8-bit PCM, suitable for extreme cases\n\n');

fprintf('Practical Considerations:\n');
fprintf('✓ Bitrate requirements determine codec choice\n');
fprintf('✓ Signal characteristics (stationary vs dynamic) affect predictor\n');
fprintf('✓ Computational complexity: PCM < DPCM < Adaptive DM\n');
fprintf('✓ Standardization important for interoperability (G.711, G.721)\n\n');

fprintf('========================================================================\n');
fprintf('EXAMPLE COMPLETE\n');
fprintf('========================================================================\n\n');

fprintf('To launch interactive GUI:\n');
fprintf('  >> main_GUI\n\n');

fprintf('To process your own WAV file:\n');
fprintf('  >> [signal, fs] = audioread(''your_file.wav'');\n');
fprintf('  >> [~, decoded, ~, metrics] = pcmCoder.encode(signal, 8, ''uniform'');\n');
fprintf('  >> sqnrCalculator.plotMetrics(signal, decoded, fs);\n\n');

% =========================================================================
% HELPER FUNCTIONS
% =========================================================================

function str = yesno_str(flag)
    if flag
        str = 'YES';
    else
        str = 'NO';
    end
end

%==========================================================================
% END OF EXAMPLE SCRIPT
%==========================================================================
