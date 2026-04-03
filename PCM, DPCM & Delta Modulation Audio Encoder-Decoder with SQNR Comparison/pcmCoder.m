%==========================================================================
% PCM CODER - Pulse Code Modulation Encoder/Decoder
%==========================================================================
% Standard linear PCM as used in CD audio, digital telephony, etc.
%
% Process:
%   1. Sampling (analog to discrete time)
%   2. Quantization (amplitude discretization)
%   3. Encoding (binary representation)
%   4. Transmission/Storage
%   5. Decoding (inverse quantization)
%   6. Reconstruction (analog approximation)
%
% Usage:
%   [encoded, decoded] = pcmCoder(signal, bitDepth, quantType)
%
% Inputs:
%   signal      - Input signal (sampled)
%   bitDepth    - Bits per sample (8, 12, 16, 24, 32)
%   quantType   - 'uniform', 'alaw', 'mulaw'
%   fs          - Sampling frequency (Hz)
%
% Outputs:
%   encoded     - Binary encoded PCM stream
%   decoded     - Reconstructed analog signal
%
%==========================================================================

classdef pcmCoder
    % Professional PCM implementation
    
    properties (Constant)
        % Standard PCM configurations
        PCM_8_LINEAR = 1;      % 8-bit linear PCM
        PCM_16_LINEAR = 2;     % 16-bit linear PCM (CD quality)
        PCM_16_ALAW = 3;       % 8-bit A-law (telephony)
        PCM_16_MULAW = 4;      % 8-bit µ-law (telephony)
    end
    
    methods (Static)
        
        %==================================================================
        % MAIN PCM ENCODING FUNCTION
        %==================================================================
        function [encoded, decoded, bitstream, metrics] = encode(signal, bitDepth, quantType, fs)
            % Encodes signal to PCM format
            %
            % Theory:
            %   Bitrate = fs * bitDepth
            %   Example: 8000 Hz * 8 bits = 64 kbps (telephony standard)
            
            if nargin < 3
                quantType = 'uniform';
            end
            if nargin < 4
                fs = 8000;
            end
            
            % Validate inputs
            validateattributes(signal, {'numeric'}, {'real', 'vector', 'finite'});
            validateattributes(bitDepth, {'numeric'}, {'scalar', '>=', 1, '<=', 32});
            
            % --------- STAGE 1: NORMALIZATION ---------
            % Ensure signal is normalized to [-1, 1]
            signal = signal / (max(abs(signal)) + eps);
            
            % --------- STAGE 2: QUANTIZATION ---------
            [q_signal, levels] = audioQuantizer.quantize(signal, bitDepth, quantType);
            
            % --------- STAGE 3: BINARY ENCODING ---------
            % Convert quantized levels to binary representation
            numLevels = 2^bitDepth;
            
            % Find indices of quantization levels (implicit encoding)
            [~, indices] = min(abs(signal(:) - levels(:)'), [], 2);
            indices = reshape(indices, size(signal));
            
            % Convert to binary (for visualization/storage)
            bitstream = de2bi(indices - 1, bitDepth, 'left-msb'); % Indices are 1-based
            
            % --------- STAGE 4: DECODING ---------
            % Explicit reconstruction: use quantized signal
            decoded = q_signal;
            
            % For proper binary format storage
            encoded = indices - 1; % 0-based indexing
            
            % --------- STAGE 5: CALCULATE METRICS ---------
            metrics.bitDepth = bitDepth;
            metrics.bitrate = fs * bitDepth;
            metrics.numLevels = numLevels;
            metrics.quantType = quantType;
            metrics.fs = fs;
            
            % Quantization statistics
            q_error = signal - decoded;
            metrics.rms_error = sqrt(mean(q_error.^2));
            metrics.max_error = max(abs(q_error));
            metrics.mean_error = mean(q_error);
            
            % Signal power
            metrics.signal_power = mean(signal.^2);
            metrics.noise_power = mean(q_error.^2);
            
            % SQNR (Signal-to-Quantization-Noise Ratio)
            if metrics.noise_power > 0
                metrics.sqnr = 10 * log10(metrics.signal_power / metrics.noise_power);
            else
                metrics.sqnr = inf;
            end
            
            % Theoretical SQNR for uniform PCM
            metrics.sqnr_theoretical = 6.02 * bitDepth + 1.76;
            
            % Compression ratio (original vs encoded)
            metrics.compression_ratio = 1.0; % PCM has no compression
            
            % Bitstream efficiency
            metrics.entropy = audioQuantizer.calculateEntropy(encoded, numLevels);
            metrics.redundancy = log2(numLevels) - metrics.entropy;
        end
        
        
        %==================================================================
        % BATCH ENCODING WITH DIFFERENT BIT DEPTHS
        %==================================================================
        function results = compareQuantizations(signal, quantType, bitDepths, fs)
            % Compare PCM performance across multiple bit depths
            %
            % Outputs structure array with metrics for each bit depth
            
            if nargin < 2
                quantType = 'uniform';
            end
            if nargin < 3
                bitDepths = [4, 6, 8, 12, 16];
            end
            if nargin < 4
                fs = 8000;
            end
            
            results = struct('bitDepth', {}, 'decoded', {}, 'metrics', {});
            
            for i = 1:length(bitDepths)
                [~, decoded, ~, metrics] = pcmCoder.encode(signal, bitDepths(i), quantType, fs);
                
                results(i).bitDepth = bitDepths(i);
                results(i).decoded = decoded;
                results(i).metrics = metrics;
            end
        end
        
        
        %==================================================================
        % FRAME-BASED ENCODING (For streaming applications)
        %==================================================================
        function [frames, frame_metrics] = encodeFrames(signal, bitDepth, quantType, fs, frameLength)
            % Encodes signal in frames (used in practical systems)
            %
            % Frame lengths (typical):
            %   20 ms @ 8 kHz = 160 samples
            %   10 ms @ 8 kHz = 80 samples
            %   5 ms @ 16 kHz = 80 samples
            
            if nargin < 5
                frameLength = round(fs * 0.020); % 20 ms frames
            end
            
            % Pad signal if needed
            padLength = frameLength - mod(length(signal), frameLength);
            if padLength > 0 && padLength < frameLength
                signal = [signal; zeros(padLength, 1)];
            end
            
            numFrames = length(signal) / frameLength;
            frames = cell(numFrames, 1);
            frame_metrics = cell(numFrames, 1);
            
            % Process each frame
            for i = 1:numFrames
                startIdx = (i-1) * frameLength + 1;
                endIdx = min(i * frameLength, length(signal));
                frameData = signal(startIdx:endIdx);
                
                % Encode frame
                [~, decoded, ~, metrics] = pcmCoder.encode(frameData, bitDepth, quantType, fs);
                
                frames{i} = decoded;
                frame_metrics{i} = metrics;
            end
            
            % Combine frames
            frames = cell2mat(frames);
            frames = frames(1:length(signal) - padLength); % Remove padding
        end
        
        
        %==================================================================
        % RECONSTRUCTION WITH INTERPOLATION
        %==================================================================
        function reconstructed = reconstructWithInterpolation(encoded, bitDepth, method)
            % Reconstructs signal with various interpolation methods
            %
            % Methods:
            %   'hold'      - Zero-order hold (fast)
            %   'linear'    - Linear interpolation (common)
            %   'spline'    - Cubic spline (smooth)
            
            if nargin < 3
                method = 'linear';
            end
            
            numLevels = 2^bitDepth;
            levels = linspace(-1, 1, numLevels);
            decoded = levels(encoded + 1); % Convert indices to levels
            
            switch lower(method)
                case 'hold'
                    % Zero-order hold (repeat samples)
                    reconstructed = decoded;
                    
                case 'linear'
                    % Linear interpolation
                    x_orig = 1:length(decoded);
                    x_interp = linspace(1, length(decoded), length(decoded) * 4);
                    reconstructed = interp1(x_orig, decoded, x_interp, 'linear');
                    
                case 'spline'
                    % Cubic spline interpolation
                    x_orig = 1:length(decoded);
                    x_interp = linspace(1, length(decoded), length(decoded) * 4);
                    reconstructed = interp1(x_orig, decoded, x_interp, 'spline');
                    
                otherwise
                    error('Unknown interpolation method: %s', method);
            end
        end
        
        
        %==================================================================
        % ANALYSIS TOOLS
        %==================================================================
        function [snr_db] = calculateSNR(original, reconstructed)
            % Calculate Signal-to-Noise Ratio
            
            error = original - reconstructed;
            signal_power = mean(original.^2);
            noise_power = mean(error.^2);
            
            if noise_power > 0
                snr_db = 10 * log10(signal_power / noise_power);
            else
                snr_db = inf;
            end
        end
        
        
        function [freq_error, freq_original, freq_reconstructed] = frequencyAnalysis(original, reconstructed, fs)
            % FFT-based frequency analysis
            
            N = length(original);
            freq = (0:N-1) * fs / N;
            freq = freq(1:N/2); % One-sided spectrum
            
            % Magnitude spectrum
            fft_orig = abs(fft(original, N));
            fft_recon = abs(fft(reconstructed, N));
            
            freq_original = fft_orig(1:N/2);
            freq_reconstructed = fft_recon(1:N/2);
            freq_error = freq_original - freq_reconstructed;
        end
        
        
        %==================================================================
        % VISUALIZATION HELPER
        %==================================================================
        function plotComparison(signal, decoded, bitDepth, quantType)
            % Plot original vs reconstructed signal
            
            if nargin < 4
                quantType = 'uniform';
            end
            
            figure('Name', sprintf('PCM Analysis - %d bits (%s)', bitDepth, quantType));
            
            % Time-domain signals
            subplot(2,2,1);
            t = 1:min(500, length(signal));
            plot(t, signal(t), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original');
            hold on;
            plot(t, decoded(t), 'r.', 'MarkerSize', 6, 'DisplayName', 'PCM');
            xlabel('Sample'); ylabel('Amplitude');
            title('Time-Domain Waveforms');
            legend; grid on;
            
            % Quantization error
            subplot(2,2,2);
            error = signal - decoded;
            plot(t, error(t), 'k-', 'LineWidth', 1);
            xlabel('Sample'); ylabel('Error');
            title('Quantization Error');
            grid on;
            
            % Error histogram
            subplot(2,2,3);
            histogram(error, 50, 'FaceColor', 'cyan', 'EdgeColor', 'black');
            xlabel('Error Value');
            ylabel('Frequency');
            title('Error Distribution');
            grid on;
            
            % Frequency spectrum
            subplot(2,2,4);
            N = length(signal);
            freq = 0:1:N-1;
            spec_orig = abs(fft(signal, N));
            spec_recon = abs(fft(decoded, N));
            plot(freq(1:N/2), spec_orig(1:N/2), 'b-', 'DisplayName', 'Original');
            hold on;
            plot(freq(1:N/2), spec_recon(1:N/2), 'r--', 'DisplayName', 'PCM');
            xlabel('Frequency Bin');
            ylabel('Magnitude');
            title('Frequency Spectrum');
            legend; grid on;
        end
    end
end

%==========================================================================
% EXAMPLE USAGE
%==========================================================================
%
% % 1. Simple PCM encoding
% t = linspace(0, 1, 8000);
% signal = sin(2*pi*1000*t)' + 0.1*sin(2*pi*3000*t)';
%
% [encoded, decoded, bitstream, metrics] = pcmCoder.encode(signal, 8, 'uniform');
%
% fprintf('PCM Metrics:\n');
% fprintf('  Bitrate: %d kbps\n', metrics.bitrate/1000);
% fprintf('  SQNR: %.2f dB (theoretical: %.2f dB)\n', metrics.sqnr, metrics.sqnr_theoretical);
% fprintf('  RMS Error: %.6f\n', metrics.rms_error);
%
% % 2. Compare quantization types
% results = pcmCoder.compareQuantizations(signal, 'uniform', [4 6 8 12 16]);
%
% % Plot comparison
% figure; hold on;
% for i = 1:length(results)
%     sqnr_vals(i) = results(i).metrics.sqnr;
%     bit_vals(i) = results(i).metrics.bitDepth;
% end
% plot(bit_vals, sqnr_vals, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
% xlabel('Bit Depth'); ylabel('SQNR (dB)');
% title('PCM Performance vs Bit Depth');
% grid on;
%
%==========================================================================
