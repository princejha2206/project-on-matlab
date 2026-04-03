%==========================================================================
% AUDIO QUANTIZER - Uniform and Non-Uniform Quantization Engine
%==========================================================================
% Implements:
%   - Uniform quantization
%   - A-law companding (ITU-G.711)
%   - µ-law companding (ITU-G.711)
%
% Usage:
%   [q_signal, levels] = audioQuantizer(signal, bitDepth, quantType)
%
% Inputs:
%   signal      - Input signal (normalized to [-1, 1])
%   bitDepth    - Number of bits (1-16)
%   quantType   - 'uniform', 'alaw', 'mulaw'
%
% Outputs:
%   q_signal    - Quantized signal
%   levels      - Quantization levels used
%   decoder     - Decoder lookup table
%
%==========================================================================

classdef audioQuantizer
    % Professional quantization engine for PCM systems
    
    properties (Constant)
        A_LAW_CONSTANT = 87.6;      % Standard A-law compression ratio
        MULAW_CONSTANT = 255;       % Standard µ-law compression ratio
        NORMALIZATION_FACTOR = 32768; % 16-bit normalization
    end
    
    methods (Static)
        
        %==================================================================
        % UNIFORM QUANTIZATION
        %==================================================================
        function [q_signal, levels, indices] = uniformQuantize(signal, bitDepth)
            % Linear quantization with uniform step size
            %
            % Mathematical basis:
            %   Δ = (x_max - x_min) / 2^bitDepth
            %   x_q = round((x - x_min) / Δ) * Δ + x_min
            %   SNR_theory = 6.02 * bitDepth + 1.76 dB
            
            % Validate inputs
            if bitDepth < 1 || bitDepth > 16
                error('BitDepth must be between 1 and 16');
            end
            
            % Ensure signal is in [-1, 1] range
            signal = signal / max(abs(signal) + eps);
            
            % Signal parameters
            x_min = -1;
            x_max = 1;
            
            % Number of quantization levels
            numLevels = 2^bitDepth;
            
            % Quantization step size (interval width)
            delta = (x_max - x_min) / numLevels;
            
            % Create quantization levels
            levels = x_min + delta/2 : delta : x_max - delta/2;
            
            % Quantize: find nearest level
            [~, indices] = min(abs(signal(:) - levels(:)'), [], 2);
            q_signal = levels(indices);
            
            % Reshape to original signal shape
            q_signal = reshape(q_signal, size(signal));
            levels = levels(:);
        end
        
        
        %==================================================================
        % A-LAW COMPANDING (ITU-G.711)
        %==================================================================
        function [q_signal, levels] = alawQuantize(signal, bitDepth)
            % ITU-T G.711 A-law companding (logarithmic quantization)
            % Standard in Europe, better for speech signals
            %
            % Compression curve:
            %   y = A|x| / (1 + ln(A))           for |x| ≤ 1/A
            %   y = (1 + ln(A|x|)) / (1 + ln(A)) for 1/A < |x| ≤ 1
            %
            % Advantages:
            %   - Better SNR for weak signals
            %   - ~13 dB improvement over uniform at -20 dBm0
            %   - Standard in telephony
            
            % Normalize signal
            signal = signal / (max(abs(signal)) + eps);
            
            % Apply A-law compression
            A = audioQuantizer.A_LAW_CONSTANT;
            c_signal = sign(signal) .* ...
                (A * abs(signal)) ./ (1 + log(A));
            c_signal(abs(signal) > 1/A) = sign(signal(abs(signal) > 1/A)) .* ...
                (1 + log(A * abs(signal(abs(signal) > 1/A)))) / (1 + log(A));
            
            % Uniform quantization of compressed signal
            numLevels = 2^bitDepth;
            c_min = -1;
            c_max = 1;
            delta = (c_max - c_min) / numLevels;
            
            levels = c_min + delta/2 : delta : c_max - delta/2;
            [~, indices] = min(abs(c_signal(:) - levels(:)'), [], 2);
            q_c_signal = levels(indices);
            q_c_signal = reshape(q_c_signal, size(signal));
            
            % Inverse A-law expansion (decompression)
            q_signal = audioQuantizer.alawExpand(q_c_signal, A);
            
            levels = audioQuantizer.alawExpand(levels, A);
        end
        
        
        %==================================================================
        % µ-LAW COMPANDING (ITU-G.711)
        %==================================================================
        function [q_signal, levels] = mulawQuantize(signal, bitDepth)
            % ITU-T G.711 µ-law companding (logarithmic quantization)
            % Standard in North America and Japan
            %
            % Compression curve:
            %   y = ln(1 + µ|x|) / ln(1 + µ) * sign(x)
            %
            % Advantages:
            %   - ~15 dB improvement over uniform at -20 dBm0
            %   - Better than A-law for wideband signals
            
            % Normalize signal
            signal = signal / (max(abs(signal)) + eps);
            
            % Apply µ-law compression
            mu = audioQuantizer.MULAW_CONSTANT;
            c_signal = sign(signal) .* log(1 + mu * abs(signal)) / log(1 + mu);
            
            % Uniform quantization of compressed signal
            numLevels = 2^bitDepth;
            c_min = -1;
            c_max = 1;
            delta = (c_max - c_min) / numLevels;
            
            levels = c_min + delta/2 : delta : c_max - delta/2;
            [~, indices] = min(abs(c_signal(:) - levels(:)'), [], 2);
            q_c_signal = levels(indices);
            q_c_signal = reshape(q_c_signal, size(signal));
            
            % Inverse µ-law expansion (decompression)
            q_signal = audioQuantizer.mulawExpand(q_c_signal, mu);
            
            levels = audioQuantizer.mulawExpand(levels, mu);
        end
        
        
        %==================================================================
        % EXPANSION FUNCTIONS (Decompression)
        %==================================================================
        function x = alawExpand(y, A)
            % Inverse A-law transformation
            if nargin < 2
                A = audioQuantizer.A_LAW_CONSTANT;
            end
            
            absY = abs(y);
            x = zeros(size(y));
            
            % First region: |y| ≤ 1/(1+ln(A))
            region1 = absY <= 1 / (1 + log(A));
            x(region1) = absY(region1) * (1 + log(A)) / A;
            
            % Second region
            region2 = ~region1;
            x(region2) = exp(absY(region2) * (1 + log(A)) - 1) / A;
            
            % Apply sign
            x = sign(y) .* x;
        end
        
        
        function x = mulawExpand(y, mu)
            % Inverse µ-law transformation
            if nargin < 2
                mu = audioQuantizer.MULAW_CONSTANT;
            end
            
            absY = abs(y);
            x = absY .* (1 + log(mu)) / mu;
            x = (exp(x) - 1) / mu;
            x = sign(y) .* x;
        end
        
        
        %==================================================================
        % UNIFIED QUANTIZATION INTERFACE
        %==================================================================
        function [q_signal, levels] = quantize(signal, bitDepth, quantType)
            % Unified interface for all quantization methods
            %
            % Inputs:
            %   signal      - Input signal
            %   bitDepth    - Bits per sample (1-16)
            %   quantType   - 'uniform' | 'alaw' | 'mulaw'
            %
            % Outputs:
            %   q_signal    - Quantized signal
            %   levels      - Quantization levels
            
            if nargin < 3
                quantType = 'uniform';
            end
            
            % Validate inputs
            validateattributes(signal, {'numeric'}, {'real', 'vector'});
            validateattributes(bitDepth, {'numeric'}, {'scalar', '>=', 1, '<=', 16});
            
            switch lower(quantType)
                case 'uniform'
                    [q_signal, levels] = audioQuantizer.uniformQuantize(signal, bitDepth);
                    
                case 'alaw'
                    [q_signal, levels] = audioQuantizer.alawQuantize(signal, bitDepth);
                    
                case 'mulaw'
                    [q_signal, levels] = audioQuantizer.mulawQuantize(signal, bitDepth);
                    
                otherwise
                    error('Unknown quantization type: %s', quantType);
            end
        end
        
        
        %==================================================================
        % QUANTIZATION STATISTICS
        %==================================================================
        function stats = getQuantizationStats(signal, q_signal, bitDepth)
            % Calculate quantization error statistics
            
            error = signal - q_signal;
            
            stats.mean_error = mean(error);
            stats.std_error = std(error);
            stats.max_error = max(abs(error));
            stats.rms_error = sqrt(mean(error.^2));
            
            % Theoretical step size
            stats.step_size = 2 / 2^bitDepth;
            stats.theoretical_max_error = stats.step_size / 2;
            
            % Entropy estimation
            stats.entropy = audioQuantizer.calculateEntropy(q_signal, 2^bitDepth);
        end
        
        
        function entropy = calculateEntropy(signal, numLevels)
            % Calculate information-theoretic entropy
            % entropy = -Σ p(x) * log2(p(x))
            
            [counts, ~] = histcounts(signal, numLevels);
            p = counts / sum(counts);
            p(p == 0) = [];
            entropy = -sum(p .* log2(p));
        end
    end
end

%==========================================================================
% EXAMPLE USAGE
%==========================================================================
% 
% % Generate test signal
% t = linspace(0, 1, 8000);
% x = sin(2*pi*1000*t);
% 
% % Apply different quantization methods
% [q_uniform, levels_u] = audioQuantizer.quantize(x, 8, 'uniform');
% [q_alaw, levels_a] = audioQuantizer.quantize(x, 8, 'alaw');
% [q_mulaw, levels_m] = audioQuantizer.quantize(x, 8, 'mulaw');
% 
% % Plot results
% figure('Position', [100 100 1200 600]);
% 
% subplot(2,2,1);
% plot(t(1:100), x(1:100), 'b-', 'LineWidth', 1.5); hold on;
% plot(t(1:100), q_uniform(1:100), 'r.', 'MarkerSize', 8);
% xlabel('Time (s)'); ylabel('Amplitude'); title('Uniform Quantization');
% legend('Original', 'Quantized');
% 
% subplot(2,2,2);
% plot(t(1:100), x(1:100), 'b-', 'LineWidth', 1.5); hold on;
% plot(t(1:100), q_alaw(1:100), 'g.', 'MarkerSize', 8);
% xlabel('Time (s)'); ylabel('Amplitude'); title('A-law Quantization');
% legend('Original', 'Quantized');
% 
% subplot(2,2,3);
% plot(t(1:100), x(1:100), 'b-', 'LineWidth', 1.5); hold on;
% plot(t(1:100), q_mulaw(1:100), 'm.', 'MarkerSize', 8);
% xlabel('Time (s)'); ylabel('Amplitude'); title('µ-law Quantization');
% legend('Original', 'Quantized');
% 
% subplot(2,2,4);
% errors = [x - q_uniform; x - q_alaw; x - q_mulaw];
% boxplot(errors', {'Uniform', 'A-law', 'µ-law'});
% ylabel('Quantization Error');
% title('Error Comparison');
%
%==========================================================================
