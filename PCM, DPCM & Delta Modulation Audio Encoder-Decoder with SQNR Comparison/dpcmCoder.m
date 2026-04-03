%==========================================================================
% DPCM CODER - Differential PCM Encoder/Decoder
%==========================================================================
% DPCM exploits signal correlation through prediction
%
% Theory:
%   e[n] = x[n] - x̂[n]              (prediction error)
%   x̂[n] = α * x_q[n-1]             (simple linear predictor)
%   encoded[n] = Q(e[n])             (quantize error)
%   decoded[n] = encoded[n] + x̂[n]  (reconstruct)
%
% Advantages:
%   - Prediction gain: ~4-6 dB vs PCM
%   - Better compression for correlated signals (speech, music)
%   - Used in ADPCM (GSM, VoIP)
%
% Usage:
%   [encoded, decoded] = dpcmCoder.encode(signal, bitDepth, predictorAlpha, quantType)
%
%==========================================================================

classdef dpcmCoder
    % DPCM with various prediction orders
    
    properties (Constant)
        % Standard predictor coefficients
        ALPHA_FIRST_ORDER = 0.95;      % Simple 1st order
        ALPHA_OPTIMAL = 0.9875;        % Optimal for speech
        
        % Higher-order predictor
        COEFFICIENTS_2ND = [0.75, -0.10];  % 2nd order Wiener
        COEFFICIENTS_3RD = [0.71, -0.12, 0.04]; % 3rd order
    end
    
    methods (Static)
        
        %==================================================================
        % MAIN DPCM ENCODING FUNCTION
        %==================================================================
        function [encoded, decoded, error, metrics] = encode(signal, bitDepth, predictorAlpha, quantType, predictorOrder)
            % DPCM encoder with configurable prediction
            %
            % Inputs:
            %   signal          - Input signal
            %   bitDepth        - Bits per sample
            %   predictorAlpha  - Predictor coefficient (0-1)
            %   quantType       - 'uniform', 'alaw', 'mulaw'
            %   predictorOrder  - 1 (default), 2, or 3
            %
            % Outputs:
            %   encoded         - Difference encoded signal
            %   decoded         - Reconstructed signal
            %   error           - Prediction errors
            %   metrics         - Quality metrics
            
            if nargin < 3
                predictorAlpha = dpcmCoder.ALPHA_OPTIMAL;
            end
            if nargin < 4
                quantType = 'uniform';
            end
            if nargin < 5
                predictorOrder = 1;
            end
            
            % Validate inputs
            validateattributes(signal, {'numeric'}, {'real', 'vector', 'finite'});
            validateattributes(predictorAlpha, {'numeric'}, {'scalar', '>=', 0, '<=', 1});
            
            % Normalize signal
            signal = signal / (max(abs(signal)) + eps);
            signal = signal(:); % Ensure column vector
            
            N = length(signal);
            
            % --------- STAGE 1: PREDICTION ---------
            % Choose predictor model
            switch predictorOrder
                case 1
                    predictor = @(prev) predictorAlpha * prev;
                    x_predicted = dpcmCoder.predictFirstOrder(signal, predictorAlpha);
                    
                case 2
                    predictor = @(prev) dpcmCoder.coefficients2nd' * prev;
                    x_predicted = dpcmCoder.predictSecondOrder(signal);
                    
                case 3
                    predictor = @(prev) dpcmCoder.coefficients3rd' * prev;
                    x_predicted = dpcmCoder.predictThirdOrder(signal);
                    
                otherwise
                    error('Predictor order must be 1, 2, or 3');
            end
            
            % --------- STAGE 2: CALCULATE PREDICTION ERROR ---------
            % e[n] = x[n] - x̂[n]
            error = signal - x_predicted;
            
            % --------- STAGE 3: QUANTIZE ERROR ---------
            % Quantize the (smaller) error signal
            [q_error, error_levels] = audioQuantizer.quantize(error, bitDepth, quantType);
            
            % --------- STAGE 4: RECONSTRUCT DECODED SIGNAL ---------
            % x_q[n] = q_error[n] + x̂[n]
            decoded = x_predicted + q_error;
            
            % Encoded signal = quantized error (differences)
            encoded = q_error;
            
            % --------- STAGE 5: CALCULATE METRICS ---------
            % Prediction gain: SNR_DPCM / SNR_PCM
            pcm_error = signal - audioQuantizer.quantize(signal, bitDepth, quantType);
            pcm_error_power = mean(pcm_error.^2);
            
            dpcm_error = signal - decoded;
            dpcm_error_power = mean(dpcm_error.^2);
            
            signal_power = mean(signal.^2);
            
            metrics.bitDepth = bitDepth;
            metrics.bitrate = 8000 * bitDepth; % Assuming 8 kHz
            metrics.predictorAlpha = predictorAlpha;
            metrics.predictorOrder = predictorOrder;
            metrics.quantType = quantType;
            
            % Error statistics
            metrics.prediction_error_power = mean(error.^2);
            metrics.prediction_error_variance = var(error);
            metrics.error_reduction = metrics.prediction_error_power / signal_power;
            metrics.prediction_gain_percent = (1 - metrics.error_reduction) * 100;
            
            % SQNR
            metrics.sqnr = 10 * log10(signal_power / dpcm_error_power);
            metrics.sqnr_pcm = 10 * log10(signal_power / pcm_error_power);
            
            % Improvement over PCM
            metrics.sqnr_improvement = metrics.sqnr - metrics.sqnr_pcm;
            
            % Theoretical SQNR
            metrics.sqnr_theoretical = 6.02 * bitDepth + 1.76;
            
            % Entropy of error signal (how much compression possible)
            numLevels = 2^bitDepth;
            metrics.entropy = audioQuantizer.calculateEntropy(encoded, numLevels);
            metrics.compression_ratio = log2(numLevels) / metrics.entropy; % > 1 means compression
            
            % Residual power
            metrics.residual_power = mean(dpcm_error.^2);
            metrics.residual_power_db = 10 * log10(metrics.residual_power + eps);
        end
        
        
        %==================================================================
        % PREDICTOR MODELS
        %==================================================================
        function x_pred = predictFirstOrder(signal, alpha)
            % First-order linear predictor: x̂[n] = α * x[n-1]
            
            N = length(signal);
            x_pred = zeros(N, 1);
            x_pred(1) = signal(1); % Initial value
            
            for n = 2:N
                x_pred(n) = alpha * signal(n-1);
            end
        end
        
        
        function x_pred = predictSecondOrder(signal)
            % Second-order predictor: x̂[n] = 0.75*x[n-1] - 0.10*x[n-2]
            
            N = length(signal);
            x_pred = zeros(N, 1);
            x_pred(1) = signal(1);
            
            for n = 2:N
                if n == 2
                    x_pred(n) = 0.75 * signal(n-1);
                else
                    x_pred(n) = 0.75 * signal(n-1) - 0.10 * signal(n-2);
                end
            end
        end
        
        
        function x_pred = predictThirdOrder(signal)
            % Third-order predictor: x̂[n] = 0.71*x[n-1] - 0.12*x[n-2] + 0.04*x[n-3]
            
            N = length(signal);
            x_pred = zeros(N, 1);
            x_pred(1) = signal(1);
            
            for n = 2:N
                if n == 2
                    x_pred(n) = 0.71 * signal(n-1);
                elseif n == 3
                    x_pred(n) = 0.71 * signal(n-1) - 0.12 * signal(n-2);
                else
                    x_pred(n) = 0.71 * signal(n-1) - 0.12 * signal(n-2) + 0.04 * signal(n-3);
                end
            end
        end
        
        
        %==================================================================
        % OPTIMIZED PREDICTOR COEFFICIENT ESTIMATION
        %==================================================================
        function alpha_opt = estimateOptimalAlpha(signal)
            % Estimate optimal predictor coefficient using autocorrelation
            % α_opt = r[1] / r[0], where r is autocorrelation
            
            [acf, ~] = autocorr(signal, 1);
            alpha_opt = acf(2); % First lag
        end
        
        
        %==================================================================
        % ADAPTIVE DPCM
        %==================================================================
        function [encoded, decoded, alpha_adaptive] = encodeAdaptive(signal, bitDepth, windowSize)
            % Adaptive DPCM: update predictor coefficient per frame
            %
            % Advantages:
            %   - Better for non-stationary signals
            %   - Used in ADPCM standards
            
            if nargin < 3
                windowSize = 160; % 20 ms @ 8 kHz
            end
            
            signal = signal / (max(abs(signal)) + eps);
            signal = signal(:);
            N = length(signal);
            
            % Pad if necessary
            numFrames = ceil(N / windowSize);
            padLength = numFrames * windowSize - N;
            if padLength > 0
                signal = [signal; zeros(padLength, 1)];
            end
            
            encoded = zeros(size(signal));
            decoded = zeros(size(signal));
            alpha_adaptive = zeros(numFrames, 1);
            
            % Process each frame
            for frame = 1:numFrames
                startIdx = (frame-1) * windowSize + 1;
                endIdx = min(frame * windowSize, length(signal));
                frameLength = endIdx - startIdx + 1;
                
                frameSignal = signal(startIdx:endIdx);
                
                % Estimate optimal alpha for this frame
                if frame == 1
                    alpha = dpcmCoder.ALPHA_OPTIMAL;
                else
                    alpha = dpcmCoder.estimateOptimalAlpha(frameSignal);
                    alpha = max(0, min(1, alpha)); % Clamp to [0,1]
                end
                alpha_adaptive(frame) = alpha;
                
                % Encode frame
                [enc_frame, dec_frame, ~, ~] = dpcmCoder.encode(...
                    frameSignal, bitDepth, alpha, 'uniform', 1);
                
                encoded(startIdx:startIdx+frameLength-1) = enc_frame(1:frameLength);
                decoded(startIdx:startIdx+frameLength-1) = dec_frame(1:frameLength);
            end
            
            % Remove padding
            encoded = encoded(1:N);
            decoded = decoded(1:N);
        end
        
        
        %==================================================================
        % COMPARISON WITH DIFFERENT PREDICTORS
        %==================================================================
        function results = comparePredictors(signal, bitDepth)
            % Compare different predictor orders
            
            alphas = [0.5, 0.75, 0.9, 0.95, dpcmCoder.ALPHA_OPTIMAL];
            results = struct('alpha', {}, 'decoded', {}, 'metrics', {});
            
            idx = 1;
            for order = 1:3
                for alpha = alphas
                    [~, decoded, ~, metrics] = dpcmCoder.encode(...
                        signal, bitDepth, alpha, 'uniform', order);
                    
                    results(idx).alpha = alpha;
                    results(idx).order = order;
                    results(idx).decoded = decoded;
                    results(idx).metrics = metrics;
                    idx = idx + 1;
                end
            end
        end
        
        
        %==================================================================
        % VISUALIZATION
        %==================================================================
        function plotAnalysis(signal, decoded, error, metrics)
            % Comprehensive DPCM analysis visualization
            
            figure('Name', sprintf('DPCM Analysis - %d bits, α=%.3f', ...
                metrics.bitDepth, metrics.predictorAlpha));
            
            % Signal comparison
            subplot(3,2,1);
            t = 1:min(500, length(signal));
            plot(t, signal(t), 'b-', 'LineWidth', 1.5);
            hold on;
            plot(t, decoded(t), 'r--', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Amplitude');
            title('Original vs Reconstructed Signal');
            legend('Original', 'DPCM');
            grid on;
            
            % Prediction error
            subplot(3,2,2);
            plot(t, error(t), 'g-', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Error');
            title('Prediction Error Signal');
            grid on;
            
            % Reconstruction error
            subplot(3,2,3);
            recon_error = signal - decoded;
            plot(t, recon_error(t), 'k-', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Error');
            title('Reconstruction Error');
            grid on;
            
            % Error histogram
            subplot(3,2,4);
            histogram(recon_error, 50, 'FaceColor', 'cyan', 'EdgeColor', 'black');
            xlabel('Error Value'); ylabel('Frequency');
            title('Error Distribution');
            grid on;
            
            % Frequency spectrum
            subplot(3,2,5);
            N = length(signal);
            freq = 0:1:N-1;
            spec_orig = 10*log10(abs(fft(signal, N)).^2 + eps);
            spec_recon = 10*log10(abs(fft(decoded, N)).^2 + eps);
            plot(freq(1:N/2), spec_orig(1:N/2), 'b-');
            hold on;
            plot(freq(1:N/2), spec_recon(1:N/2), 'r--');
            xlabel('Frequency Bin'); ylabel('Power (dB)');
            title('Power Spectral Density');
            legend('Original', 'DPCM');
            grid on;
            
            % Metrics text
            subplot(3,2,6);
            axis off;
            metricsText = sprintf(...
                'DPCM Metrics:\n\n'...
                'Bit Depth: %d bits\n'...
                'Predictor Order: %d\n'...
                'Predictor α: %.4f\n\n'...
                'Prediction Gain: %.2f %%\n'...
                'Error Reduction: %.2f %%\n\n'...
                'SQNR: %.2f dB\n'...
                'SQNR (PCM): %.2f dB\n'...
                'Improvement: %.2f dB\n\n'...
                'Compression Ratio: %.3f\n'...
                'Entropy: %.2f bits', ...
                metrics.bitDepth, metrics.predictorOrder, metrics.predictorAlpha, ...
                metrics.prediction_gain_percent, metrics.error_reduction * 100, ...
                metrics.sqnr, metrics.sqnr_pcm, metrics.sqnr_improvement, ...
                metrics.compression_ratio, metrics.entropy);
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
% % Generate test signal
% t = linspace(0, 1, 8000);
% signal = sin(2*pi*1000*t)' + 0.3*sin(2*pi*3000*t)';
%
% % DPCM encoding
% [encoded, decoded, error, metrics] = dpcmCoder.encode(...
%     signal, 8, 0.95, 'uniform', 1);
%
% fprintf('DPCM Results:\n');
% fprintf('  SQNR: %.2f dB (improvement: %.2f dB over PCM)\n', ...
%     metrics.sqnr, metrics.sqnr_improvement);
% fprintf('  Prediction Error Variance: %.6f\n', metrics.prediction_error_variance);
% fprintf('  Compression Ratio: %.3f\n', metrics.compression_ratio);
%
% % Compare predictors
% results = dpcmCoder.comparePredictors(signal, 8);
%
% % Plot optimal result
% [~, idx] = max([results.metrics.sqnr]);
% dpcmCoder.plotAnalysis(signal, results(idx).decoded, error, results(idx).metrics);
%
%==========================================================================
