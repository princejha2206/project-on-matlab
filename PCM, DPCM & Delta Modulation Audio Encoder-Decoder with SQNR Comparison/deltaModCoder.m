%==========================================================================
% DELTA MODULATION CODER - 1-Bit Differential Modulation
%==========================================================================
% Extreme simplification of DPCM to single-bit output
%
% Characteristics:
%   - 1 bit per sample (extremely low bitrate)
%   - Simple encoder: compare signal with integrator output
%   - Simple decoder: low-pass filter on bit stream
%   - Trade-off: low bitrate vs granular noise and slope overload
%
% Process:
%   e[n] = x[n] - x̂[n]              (error between signal and estimate)
%   bit[n] = 1 if e[n] > 0, else 0  (1-bit quantization)
%   x̂[n] = x̂[n-1] + Δ * sign(e[n]) (update estimate)
%
% Issues:
%   - Granular noise: Δ too large → always oscillating
%   - Slope overload: Δ too small → can't follow rapid changes
%
% Theory:
%   Nyquist criterion for Δ:
%   Δ ≥ π * f_max * X_max / f_s
%
% Variants:
%   - Standard DM: fixed step size
%   - Adaptive DM: step size varies with signal activity
%   - Continuously Variable Slope DM (CVSD)
%
%==========================================================================

classdef deltaModCoder
    % Delta modulation with adaptive and fixed versions
    
    properties (Constant)
        % Standard step sizes
        STEP_SIZE_OPTIMAL = 0.1;      % Typical value for normalized signals
        STEP_SIZE_ADAPTIVE_INIT = 0.05;
        
        % Adaptation parameters
        ADAPT_FACTOR_UP = 1.5;        % Increase Δ if bits agree
        ADAPT_FACTOR_DOWN = 0.9;      % Decrease Δ if bits alternate
    end
    
    methods (Static)
        
        %==================================================================
        % STANDARD FIXED DELTA MODULATION
        %==================================================================
        function [bitstream, decoded, estimate, metrics] = encodeFixed(signal, stepSize, fs)
            % Fixed-step delta modulation
            %
            % Inputs:
            %   signal      - Input signal (normalized [-1,1])
            %   stepSize    - Fixed step size Δ (default: 0.1)
            %   fs          - Sampling frequency (Hz)
            %
            % Outputs:
            %   bitstream   - 1-bit per sample (0 or 1)
            %   decoded     - Reconstructed signal
            %   estimate    - Integrator output trajectory
            %   metrics     - Quality metrics
            
            if nargin < 2
                stepSize = deltaModCoder.STEP_SIZE_OPTIMAL;
            end
            if nargin < 3
                fs = 8000;
            end
            
            % Normalize signal
            signal = signal / (max(abs(signal)) + eps);
            signal = signal(:);
            
            N = length(signal);
            
            % --------- STAGE 1: GENERATE BIT STREAM ---------
            bitstream = zeros(N, 1);
            estimate = zeros(N, 1);
            
            % Initialize with first sample
            estimate(1) = signal(1);
            error = signal(1) - estimate(1);
            bitstream(1) = (error > 0);
            
            % --------- STAGE 2: DELTA MODULATION PROCESS ---------
            % For each sample:
            %   1. Compare input with integrator output
            %   2. Generate 1-bit output
            %   3. Update integrator based on bit
            
            for n = 2:N
                % Prediction error
                error = signal(n) - estimate(n-1);
                
                % Quantize to 1 bit
                if error > 0
                    bitstream(n) = 1;
                    delta = stepSize;
                else
                    bitstream(n) = 0;
                    delta = -stepSize;
                end
                
                % Update integrator (accumulator)
                estimate(n) = estimate(n-1) + delta;
            end
            
            % --------- STAGE 3: DECODE ---------
            % Low-pass filter the bit stream
            decoded = deltaModCoder.decodeFixedDM(bitstream, stepSize, N);
            
            % --------- STAGE 4: CALCULATE METRICS ---------
            % Bitrate: 1 bit per sample
            metrics.bitrate = fs * 1; % bits per second
            metrics.compression_ratio = 16 / 1; % vs 16-bit PCM
            metrics.step_size = stepSize;
            metrics.fs = fs;
            
            % SQNR calculation
            recon_error = signal - decoded;
            signal_power = mean(signal.^2);
            noise_power = mean(recon_error.^2);
            
            if noise_power > 0
                metrics.sqnr = 10 * log10(signal_power / noise_power);
            else
                metrics.sqnr = inf;
            end
            
            % Error statistics
            metrics.rms_error = sqrt(mean(recon_error.^2));
            metrics.max_error = max(abs(recon_error));
            metrics.mean_error = mean(recon_error);
            
            % Granular noise analysis
            % Granular noise occurs when signal is stationary
            metrics.granular_noise = deltaModCoder.analyzeGranularNoise(decoded, stepSize);
            
            % Slope overload analysis
            % Slope overload occurs when Δ is too small for rapid changes
            metrics.max_slope = max(abs(diff(signal)));
            metrics.max_slope_possible = stepSize * fs;
            metrics.slope_overload_risk = metrics.max_slope > metrics.max_slope_possible;
            
            % Bit transitions
            transitions = sum(diff(bitstream) ~= 0);
            metrics.bit_transition_rate = transitions / N;
            
            % Theoretical SQNR (rough estimate)
            metrics.sqnr_theoretical = 3 * log10(pi * fs / (2 * deltaModCoder.findMaxFreq(signal)));
        end
        
        
        %==================================================================
        % ADAPTIVE DELTA MODULATION (ADM)
        %==================================================================
        function [bitstream, decoded, estimate, stepSizes, metrics] = encodeAdaptive(signal, fs, windowSize)
            % Adaptive delta modulation with dynamic step size
            %
            % Algorithm:
            %   If consecutive bits are SAME → increase Δ (to track rapid changes)
            %   If consecutive bits DIFFER → decrease Δ (reduce granular noise)
            %
            % Used in: CVSD, adaptive audio transmission
            
            if nargin < 2
                fs = 8000;
            end
            if nargin < 3
                windowSize = 4; % Adaptation window
            end
            
            % Normalize signal
            signal = signal / (max(abs(signal)) + eps);
            signal = signal(:);
            N = length(signal);
            
            % Initialize
            bitstream = zeros(N, 1);
            estimate = zeros(N, 1);
            stepSizes = zeros(N, 1);
            
            % Initial values
            estimate(1) = signal(1);
            stepSize = deltaModCoder.STEP_SIZE_ADAPTIVE_INIT;
            stepSizes(1) = stepSize;
            
            % --------- ADAPTIVE DM ENCODING ---------
            for n = 2:N
                % Generate bit
                error = signal(n) - estimate(n-1);
                bitstream(n) = (error > 0);
                
                % Update estimate
                if bitstream(n) == 1
                    estimate(n) = estimate(n-1) + stepSize;
                else
                    estimate(n) = estimate(n-1) - stepSize;
                end
                
                % Adapt step size every windowSize samples
                if n > windowSize
                    % Check if last windowSize bits are same (consecutive agreement)
                    bit_diffs = sum(abs(diff(bitstream(n-windowSize+1:n))));
                    
                    if bit_diffs == 0
                        % All bits same → increase step size (follow faster)
                        stepSize = stepSize * deltaModCoder.ADAPT_FACTOR_UP;
                    else
                        % Bits differ → decrease step size (reduce noise)
                        stepSize = stepSize * deltaModCoder.ADAPT_FACTOR_DOWN;
                    end
                    
                    % Clamp step size
                    stepSize = max(0.01, min(0.5, stepSize));
                end
                
                stepSizes(n) = stepSize;
            end
            
            % --------- DECODE ---------
            decoded = deltaModCoder.decodeAdaptiveDM(bitstream, stepSizes, N);
            
            % --------- METRICS ---------
            metrics.bitrate = fs * 1;
            metrics.compression_ratio = 16 / 1;
            metrics.fs = fs;
            metrics.mean_step_size = mean(stepSizes);
            metrics.min_step_size = min(stepSizes);
            metrics.max_step_size = max(stepSizes);
            
            % Quality metrics
            recon_error = signal - decoded;
            signal_power = mean(signal.^2);
            noise_power = mean(recon_error.^2);
            
            if noise_power > 0
                metrics.sqnr = 10 * log10(signal_power / noise_power);
            else
                metrics.sqnr = inf;
            end
            
            metrics.rms_error = sqrt(mean(recon_error.^2));
        end
        
        
        %==================================================================
        % DECODING FUNCTIONS
        %==================================================================
        function decoded = decodeFixedDM(bitstream, stepSize, N)
            % Decode fixed-step delta modulation
            
            decoded = zeros(N, 1);
            decoded(1) = (bitstream(1) - 0.5) * 2 * stepSize;
            
            % Integrate bit stream
            for n = 2:N
                if bitstream(n) == 1
                    decoded(n) = decoded(n-1) + stepSize;
                else
                    decoded(n) = decoded(n-1) - stepSize;
                end
            end
            
            % Apply simple low-pass filter to smooth
            % Use moving average filter
            filterLength = 5;
            b = ones(1, filterLength) / filterLength;
            decoded = filtfilt(b, 1, decoded);
        end
        
        
        function decoded = decodeAdaptiveDM(bitstream, stepSizes, N)
            % Decode adaptive delta modulation
            
            decoded = zeros(N, 1);
            decoded(1) = (bitstream(1) - 0.5) * 2 * stepSizes(1);
            
            % Integrate with adaptive step sizes
            for n = 2:N
                if bitstream(n) == 1
                    decoded(n) = decoded(n-1) + stepSizes(n);
                else
                    decoded(n) = decoded(n-1) - stepSizes(n);
                end
            end
            
            % Low-pass filter
            filterLength = 5;
            b = ones(1, filterLength) / filterLength;
            decoded = filtfilt(b, 1, decoded);
        end
        
        
        %==================================================================
        % ANALYSIS FUNCTIONS
        %==================================================================
        function granular_power = analyzeGranularNoise(decoded, stepSize)
            % Estimate granular noise power in stationary regions
            
            % Approximate granular noise as ±stepSize/2
            granular_power = (stepSize / 2)^2 / 3;
        end
        
        
        function f_max = findMaxFreq(signal)
            % Estimate maximum frequency in signal using FFT
            
            N = length(signal);
            fft_mag = abs(fft(signal, N));
            [~, idx] = max(fft_mag(1:N/2));
            f_max = idx;
        end
        
        
        function optimal_delta = computeOptimalDelta(signal, fs)
            % Compute optimal step size using Nyquist criterion
            % Δ ≥ π * f_max * X_max / f_s
            
            X_max = max(abs(signal));
            f_max = deltaModCoder.findMaxFreq(signal);
            
            optimal_delta = pi * f_max * X_max / fs;
        end
        
        
        %==================================================================
        % COMPARATIVE ANALYSIS
        %==================================================================
        function results = compareStepSizes(signal, fs, stepSizes)
            % Compare performance across different step sizes
            
            if nargin < 3
                stepSizes = [0.01, 0.05, 0.1, 0.2, 0.5];
            end
            
            results = struct('stepSize', {}, 'decoded', {}, 'metrics', {});
            
            for i = 1:length(stepSizes)
                [~, decoded, ~, metrics] = deltaModCoder.encodeFixed(...
                    signal, stepSizes(i), fs);
                
                results(i).stepSize = stepSizes(i);
                results(i).decoded = decoded;
                results(i).metrics = metrics;
            end
        end
        
        
        %==================================================================
        % VISUALIZATION
        %==================================================================
        function plotAnalysis(signal, decoded, bitstream, metrics)
            % Comprehensive delta modulation analysis
            
            figure('Name', sprintf('Delta Modulation - Δ=%.4f', metrics.step_size));
            
            % Original vs Reconstructed
            subplot(3,2,1);
            t = 1:min(500, length(signal));
            plot(t, signal(t), 'b-', 'LineWidth', 1.5);
            hold on;
            plot(t, decoded(t), 'r--', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Amplitude');
            title('Signal Reconstruction');
            legend('Original', 'Delta Decoded');
            grid on;
            
            % Bitstream visualization
            subplot(3,2,2);
            plot(t, bitstream(t), 'g-', 'LineWidth', 2);
            set(gca, 'YLim', [-0.2, 1.2]);
            xlabel('Sample'); ylabel('Bit Value');
            title('1-Bit Bitstream');
            grid on;
            
            % Error signal
            subplot(3,2,3);
            error = signal - decoded;
            plot(t, error(t), 'k-', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Error');
            title('Reconstruction Error');
            grid on;
            
            % Error histogram
            subplot(3,2,4);
            histogram(error, 50, 'FaceColor', 'cyan', 'EdgeColor', 'black');
            xlabel('Error Value'); ylabel('Frequency');
            title('Error Distribution');
            grid on;
            
            % FFT Comparison
            subplot(3,2,5);
            N = length(signal);
            freq = 0:1:N-1;
            spec_orig = 10*log10(abs(fft(signal, N)).^2 + eps);
            spec_recon = 10*log10(abs(fft(decoded, N)).^2 + eps);
            plot(freq(1:N/2), spec_orig(1:N/2), 'b-');
            hold on;
            plot(freq(1:N/2), spec_recon(1:N/2), 'r--');
            xlabel('Frequency Bin'); ylabel('Power (dB)');
            title('Frequency Response');
            legend('Original', 'Decoded');
            grid on;
            
            % Metrics display
            subplot(3,2,6);
            axis off;
            metricsText = sprintf(...
                'Delta Modulation Metrics:\n\n'...
                'Step Size: %.4f\n'...
                'Bitrate: %d bps\n'...
                'Compression: %d:1\n\n'...
                'SQNR: %.2f dB\n'...
                'RMS Error: %.6f\n'...
                'Max Error: %.6f\n\n'...
                'Max Slope: %.4f\n'...
                'Max Possible: %.4f\n'...
                'Slope Overload: %s\n\n'...
                'Bit Transition: %.2f %%', ...
                metrics.step_size, metrics.bitrate, metrics.compression_ratio, ...
                metrics.sqnr, metrics.rms_error, metrics.max_error, ...
                metrics.max_slope, metrics.max_slope_possible, ...
                yesno(metrics.slope_overload_risk), ...
                metrics.bit_transition_rate * 100);
            text(0.1, 0.9, metricsText, 'Units', 'normalized', ...
                'VerticalAlignment', 'top', 'FontFamily', 'monospace', ...
                'FontSize', 9, 'BackgroundColor', [0.9 0.9 0.9]);
        end
    end
end

% Helper function
function str = yesno(flag)
    if flag
        str = 'YES';
    else
        str = 'NO';
    end
end

%==========================================================================
% EXAMPLE USAGE
%==========================================================================
%
% % Generate test signal
% t = linspace(0, 1, 8000);
% signal = sin(2*pi*1000*t)' + 0.2*cos(2*pi*2000*t)';
%
% % Fixed Delta Modulation
% [bits, decoded, est, metrics] = deltaModCoder.encodeFixed(signal, 0.1);
%
% fprintf('Fixed Delta Modulation:\n');
% fprintf('  Bitrate: %d bps\n', metrics.bitrate);
% fprintf('  SQNR: %.2f dB\n', metrics.sqnr);
% fprintf('  Slope Overload Risk: %s\n', yesno(metrics.slope_overload_risk));
%
% % Adaptive Delta Modulation
% [bits_adp, dec_adp, ~, stepSizes, metrics_adp] = deltaModCoder.encodeAdaptive(signal);
%
% fprintf('\nAdaptive Delta Modulation:\n');
% fprintf('  Mean Step Size: %.4f\n', metrics_adp.mean_step_size);
% fprintf('  SQNR: %.2f dB\n', metrics_adp.sqnr);
%
% % Compare step sizes
% results = deltaModCoder.compareStepSizes(signal, 8000, [0.05, 0.1, 0.15, 0.2]);
%
% % Plot
% figure;
% for i = 1:length(results)
%     sqnr_vals(i) = results(i).metrics.sqnr;
%     step_vals(i) = results(i).stepSize;
% end
% semilogx(step_vals, sqnr_vals, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
% xlabel('Step Size Δ'); ylabel('SQNR (dB)');
% title('Delta Modulation: SQNR vs Step Size');
% grid on;
%
%==========================================================================
