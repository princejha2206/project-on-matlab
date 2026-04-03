%==========================================================================
% SQNR CALCULATOR - Signal-to-Quantization-Noise-Ratio Analysis
%==========================================================================
% Comprehensive quality metrics for audio codecs
%
% SQNR Definition:
%   SQNR = 10 * log10(P_signal / P_noise)
%   P_signal = (1/N) * Σ x[n]²        (signal power)
%   P_noise = (1/N) * Σ (x[n] - y[n])² (error power)
%
% Theoretical Values:
%   Uniform PCM: SQNR = 6.02*b + 1.76 dB
%   DPCM: ~4-6 dB better than PCM
%   Delta Mod: ~3*b dB (very rough)
%
% Other Metrics:
%   PESQ (Perceptual) - not implemented
%   MOS (Mean Opinion Score) - not implemented
%   THD (Total Harmonic Distortion)
%   SNR (Signal-to-Noise Ratio)
%
%==========================================================================

classdef sqnrCalculator
    % Comprehensive quantization quality metrics
    
    properties (Constant)
        % Reference power levels (dBm0 - digital signal reference)
        DBMO_REFERENCE = 0.001; % -20 dBm0 = 0.001 in normalized units
    end
    
    methods (Static)
        
        %==================================================================
        % BASIC SQNR CALCULATION
        %==================================================================
        function sqnr_db = calculateSQNR(original, reconstructed)
            % Calculate Signal-to-Quantization-Noise Ratio
            %
            % Inputs:
            %   original        - Original signal
            %   reconstructed   - Reconstructed/quantized signal
            %
            % Output:
            %   sqnr_db         - SQNR in decibels
            
            % Ensure vectors
            original = original(:);
            reconstructed = reconstructed(:);
            
            % Validate
            if length(original) ~= length(reconstructed)
                error('Signals must have same length');
            end
            
            % Calculate powers
            signal_power = sqnrCalculator.calculateSignalPower(original);
            noise_power = sqnrCalculator.calculateNoisePower(original, reconstructed);
            
            % Avoid division by zero
            if noise_power == 0
                sqnr_db = inf;
            else
                sqnr_db = 10 * log10(signal_power / noise_power);
            end
        end
        
        
        function sqnr_db = calculateSQNRPercent(original, reconstructed)
            % SQNR as percentage of maximum possible
            
            sqnr_db = sqnrCalculator.calculateSQNR(original, reconstructed);
            
            % Maximum possible (no quantization error)
            max_sqnr = inf;
        end
        
        
        %==================================================================
        % POWER CALCULATIONS
        %==================================================================
        function power = calculateSignalPower(signal)
            % Calculate RMS power of signal
            % P_signal = (1/N) * Σ |x[n]|²
            
            signal = signal(:);
            power = mean(signal.^2);
            
            % Avoid zero power
            if power == 0
                power = eps;
            end
        end
        
        
        function power = calculateNoisePower(original, reconstructed)
            % Calculate power of quantization noise
            % P_noise = (1/N) * Σ |e[n]|²
            % where e[n] = original[n] - reconstructed[n]
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            error = original - reconstructed;
            power = mean(error.^2);
        end
        
        
        function power_db = getPowerInDB(signal, reference)
            % Get signal power in dB relative to reference
            % P_dB = 10 * log10(P_signal / P_reference)
            
            if nargin < 2
                reference = 1.0;
            end
            
            signal = signal(:);
            power = mean(signal.^2);
            power_db = 10 * log10(power / reference);
        end
        
        
        %==================================================================
        % DETAILED METRIC CALCULATION
        %==================================================================
        function metrics = calculateDetailedMetrics(original, reconstructed, fs)
            % Calculate comprehensive set of quality metrics
            %
            % Returns structure with all relevant metrics
            
            if nargin < 3
                fs = 8000;
            end
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            % --------- BASIC METRICS ---------
            metrics.sqnr = sqnrCalculator.calculateSQNR(original, reconstructed);
            metrics.snr = sqnrCalculator.calculateSNR(original, reconstructed);
            
            % --------- ERROR STATISTICS ---------
            error = original - reconstructed;
            metrics.rms_error = sqrt(mean(error.^2));
            metrics.mean_error = mean(error);
            metrics.std_error = std(error);
            metrics.max_error = max(abs(error));
            metrics.min_error = min(error);
            
            % --------- POWER METRICS ---------
            metrics.original_power = sqnrCalculator.calculateSignalPower(original);
            metrics.original_power_db = 10 * log10(metrics.original_power);
            metrics.noise_power = sqnrCalculator.calculateNoisePower(original, reconstructed);
            metrics.noise_power_db = 10 * log10(metrics.noise_power);
            
            % --------- PEAK METRICS ---------
            metrics.peak_original = max(abs(original));
            metrics.peak_reconstructed = max(abs(reconstructed));
            metrics.crest_factor_original = metrics.peak_original / sqrt(metrics.original_power);
            metrics.crest_factor_reconstructed = metrics.peak_reconstructed / sqrt(mean(reconstructed.^2));
            
            % --------- HARMONIC DISTORTION ---------
            metrics.thd = sqnrCalculator.calculateTHD(original, reconstructed);
            metrics.sinad = sqnrCalculator.calculateSINAD(original, reconstructed);
            metrics.enob = sqnrCalculator.calculateENOB(metrics.sqnr); % Effective Number of Bits
            
            % --------- SPECTRAL METRICS ---------
            [metrics.snr_spec, metrics.freq_spectrum] = sqnrCalculator.spectralSNR(original, reconstructed, fs);
            
            % --------- CORRELATION ---------
            metrics.correlation = sqnrCalculator.calculateCorrelation(original, reconstructed);
            
            % --------- PERCEPTUAL METRICS ---------
            % Simple approximations (not ITU standards)
            metrics.weighted_noise = sqnrCalculator.weightedNoisePower(error, fs);
            metrics.loudness = sqnrCalculator.estimateLoudness(original);
            
            % --------- FREQUENCY CONTENT ---------
            metrics.signal_bandwidth = sqnrCalculator.estimateBandwidth(original, fs);
            metrics.error_bandwidth = sqnrCalculator.estimateBandwidth(error, fs);
            
            % --------- DISTORTION METRICS ---------
            metrics.mean_absolute_error = mean(abs(error));
            metrics.median_error = median(error);
            
            % --------- SIGNAL CHARACTERISTICS ---------
            metrics.zero_crossing_rate = sqnrCalculator.zerosCrossingRate(original);
            metrics.peak_to_average = metrics.peak_original / sqrt(metrics.original_power);
        end
        
        
        %==================================================================
        % ADVANCED QUALITY METRICS
        %==================================================================
        function snr_db = calculateSNR(original, reconstructed)
            % SNR (not just SQNR) - includes all distortions
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            signal_power = mean((original - mean(original)).^2);
            error = original - reconstructed;
            error_power = mean(error.^2);
            
            if error_power > 0
                snr_db = 10 * log10(signal_power / error_power);
            else
                snr_db = inf;
            end
        end
        
        
        function thd_percent = calculateTHD(original, reconstructed)
            % Total Harmonic Distortion
            % Approximation: ratio of harmonics to fundamental
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            % Very simplified version (proper THD requires sinusoid identification)
            error = original - reconstructed;
            fundamental_power = mean(original.^2);
            harmonic_power = mean(error.^2);
            
            if fundamental_power > 0
                thd_percent = 100 * sqrt(harmonic_power / fundamental_power);
            else
                thd_percent = 0;
            end
        end
        
        
        function sinad_db = calculateSINAD(original, reconstructed)
            % Signal-to-Noise-and-Distortion Ratio
            % SINAD = signal / (noise + distortion)
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            % Remove DC component
            original_ac = original - mean(original);
            reconstructed_ac = reconstructed - mean(reconstructed);
            
            signal_power = mean(original_ac.^2);
            error = original_ac - reconstructed_ac;
            noise_distortion_power = mean(error.^2);
            
            if noise_distortion_power > 0
                sinad_db = 10 * log10(signal_power / noise_distortion_power);
            else
                sinad_db = inf;
            end
        end
        
        
        function enob = calculateENOB(sqnr_db)
            % Effective Number of Bits from SQNR
            % SQNR_dB = 6.02*ENOB + 1.76
            % ENOB = (SQNR_dB - 1.76) / 6.02
            
            enob = (sqnr_db - 1.76) / 6.02;
            enob = max(0, enob);
        end
        
        
        function [snr_spectrum, freq_bins] = spectralSNR(original, reconstructed, fs)
            % Calculate SNR in frequency domain
            
            N = length(original);
            freq = (0:N-1) * fs / N;
            
            X = fft(original);
            Y = fft(reconstructed);
            E = X - Y;
            
            % Power spectral density
            signal_spectrum = abs(X).^2 / N;
            error_spectrum = abs(E).^2 / N;
            
            % Avoid division by zero
            snr_spectrum = 10 * log10(signal_spectrum ./ (error_spectrum + eps));
            freq_bins = freq(1:N/2);
            snr_spectrum = snr_spectrum(1:N/2);
        end
        
        
        function corr = calculateCorrelation(original, reconstructed)
            % Correlation coefficient between original and reconstructed
            
            original = original(:);
            reconstructed = reconstructed(:);
            
            % Normalize
            orig_norm = (original - mean(original)) / std(original);
            recon_norm = (reconstructed - mean(reconstructed)) / std(reconstructed);
            
            corr = mean(orig_norm .* recon_norm);
        end
        
        
        function weighted_power = weightedNoisePower(error, fs)
            % Frequency-weighted noise power (A-weighting approximation)
            % Gives more weight to mid-frequencies
            
            error = error(:);
            
            % Simple A-weighting (ITU approximation)
            N = length(error);
            freq = (0:N-1) * fs / N;
            
            % A-weight coefficients (rough)
            f = freq(1:N/2);
            A_weight = 1 ./ (1 + (f / 1000).^2); % Simplified A-curve
            A_weight = [A_weight, fliplr(A_weight(2:end))];
            
            error_fft = abs(fft(error)).^2 / N;
            weighted_power = mean(error_fft .* A_weight(:));
        end
        
        
        function loudness_dbfs = estimateLoudness(signal)
            % Estimate loudness in dBFS (relative to full scale)
            
            signal = signal(:);
            peak = max(abs(signal));
            rms = sqrt(mean(signal.^2));
            
            loudness_dbfs = 20 * log10(rms / (peak + eps));
        end
        
        
        function bandwidth = estimateBandwidth(signal, fs)
            % Estimate 3dB bandwidth of signal
            
            signal = signal(:);
            N = length(signal);
            
            % Magnitude spectrum
            spectrum = abs(fft(signal, N)).^2;
            spectrum = spectrum(1:N/2);
            
            % Find peak
            [peak_val, peak_idx] = max(spectrum);
            
            % Find 3dB points
            half_power = peak_val / 2;
            above_half = spectrum > half_power;
            
            indices = find(above_half);
            if ~isempty(indices)
                bandwidth = (indices(end) - indices(1)) * fs / N;
            else
                bandwidth = 0;
            end
        end
        
        
        function zcr = zerosCrossingRate(signal)
            % Zero-crossing rate (transitions per sample)
            
            signal = signal(:);
            sign_changes = sum(abs(diff(sign(signal)))) / 2;
            zcr = sign_changes / length(signal);
        end
        
        
        %==================================================================
        % COMPARISON AND VISUALIZATION
        %==================================================================
        function compareMetrics(metrics_cell, labels)
            % Compare metrics across multiple codecs
            
            % Extract SQNR values
            sqnr_values = [];
            for i = 1:length(metrics_cell)
                sqnr_values(i) = metrics_cell{i}.sqnr;
            end
            
            % Create comparison
            figure('Position', [100 100 1200 600]);
            
            % Bar plot
            subplot(1,2,1);
            bar(sqnr_values, 'FaceColor', 'cyan', 'EdgeColor', 'black');
            set(gca, 'XTickLabel', labels);
            ylabel('SQNR (dB)');
            title('SQNR Comparison');
            grid on;
            
            % Table
            subplot(1,2,2);
            axis off;
            tableData = [];
            for i = 1:length(metrics_cell)
                m = metrics_cell{i};
                tableData(i,:) = [m.sqnr, m.rms_error, m.mean_error, m.max_error];
            end
            
            colLabels = {'SQNR (dB)', 'RMS Error', 'Mean Error', 'Max Error'};
            rowLabels = labels;
            
            h = uitable('Data', tableData, ...
                'ColumnName', colLabels, ...
                'RowName', rowLabels, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
            h.ColumnWidth = {100, 100, 100, 100};
        end
        
        
        function plotMetrics(original, reconstructed, fs, title_str)
            % Plot detailed metrics
            
            if nargin < 4
                title_str = 'Quality Analysis';
            end
            
            metrics = sqnrCalculator.calculateDetailedMetrics(original, reconstructed, fs);
            
            figure('Name', title_str);
            
            % SQNR and SNR
            subplot(2,3,1);
            bar([metrics.sqnr, metrics.snr, metrics.sinad], ...
                'FaceColor', 'cyan', 'EdgeColor', 'black');
            set(gca, 'XTickLabel', {'SQNR', 'SNR', 'SINAD'});
            ylabel('dB');
            title('Quality Metrics');
            grid on;
            
            % Error statistics
            subplot(2,3,2);
            boxplot([metrics.mean_error, metrics.std_error, metrics.max_error], ...
                {'Mean', 'Std Dev', 'Max'});
            ylabel('Error (linear)');
            title('Error Statistics');
            grid on;
            
            % Power spectrum
            subplot(2,3,3);
            plot(metrics.freq_spectrum, metrics.snr_spec, 'b-', 'LineWidth', 1);
            xlabel('Frequency (Hz)');
            ylabel('SNR (dB)');
            title('Spectral SNR');
            grid on;
            
            % Correlation
            subplot(2,3,4);
            plot([metrics.correlation], 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            set(gca, 'XLim', [0.5 1.5], 'YLim', [0.5 1.05]);
            ylabel('Correlation');
            title('Signal Correlation');
            grid on;
            
            % ENOB
            subplot(2,3,5);
            enob = metrics.enob;
            bar(enob, 'FaceColor', 'yellow', 'EdgeColor', 'black');
            set(gca, 'XTickLabel', {'ENOB'});
            ylabel('Bits');
            title('Effective Number of Bits');
            grid on;
            
            % Metrics text
            subplot(2,3,6);
            axis off;
            metricsText = sprintf(...
                'Summary Metrics:\n\n'...
                'SQNR: %.2f dB\n'...
                'SNR: %.2f dB\n'...
                'SINAD: %.2f dB\n'...
                'ENOB: %.2f bits\n'...
                'THD: %.4f %%\n'...
                'RMS Error: %.6f\n'...
                'Crest Factor: %.2f\n'...
                'Zero Cross Rate: %.4f', ...
                metrics.sqnr, metrics.snr, metrics.sinad, metrics.enob, ...
                metrics.thd, metrics.rms_error, metrics.crest_factor_original, ...
                metrics.zero_crossing_rate);
            text(0.1, 0.9, metricsText, 'Units', 'normalized', ...
                'VerticalAlignment', 'top', 'FontFamily', 'monospace', ...
                'FontSize', 10, 'BackgroundColor', [0.9 0.9 0.9]);
        end
    end
end

%==========================================================================
% EXAMPLE USAGE
%==========================================================================
%
% % Generate test signals
% t = linspace(0, 1, 8000);
% signal = sin(2*pi*1000*t)' + 0.2*sin(2*pi*3000*t)';
%
% % Apply quantization
% [q_signal, ~] = audioQuantizer.quantize(signal, 8, 'uniform');
%
% % Calculate metrics
% metrics = sqnrCalculator.calculateDetailedMetrics(signal, q_signal, 8000);
%
% fprintf('Audio Quality Metrics:\n');
% fprintf('  SQNR: %.2f dB\n', metrics.sqnr);
% fprintf('  SNR: %.2f dB\n', metrics.snr);
% fprintf('  SINAD: %.2f dB\n', metrics.sinad);
% fprintf('  ENOB: %.2f bits\n', metrics.enob);
% fprintf('  THD: %.4f %%\n', metrics.thd);
% fprintf('  Correlation: %.4f\n', metrics.correlation);
%
% % Plot metrics
% sqnrCalculator.plotMetrics(signal, q_signal, 8000, '8-bit Uniform Quantization');
%
%==========================================================================
