clc;
clear;
close all;

%% 1. Parameter Definition
f_m = 1;              % Message signal frequency (Hz)
f_s = 20;             % Sampling frequency (Hz)
n_bits = 4;           % PCM resolution (bits per sample)
A = 1;                % Signal amplitude
t = 0:0.001:2;        % Continuous-time vector (2 seconds duration)
t_s = 0:1/f_s:2;      % Discrete sampling instants

%% 2. Signal Generation

% A. Continuous-time input signal
x_analog = A * sin(2 * pi * f_m * t);

% B. Sampling and quantization process
L = 2^n_bits;                       % Total quantization levels
x_sampled = A * sin(2 * pi * f_m * t_s);
x_min = -A; x_max = A;               % Quantizer range
delta = (x_max - x_min) / L;         % Step size
q_level = round((x_sampled - x_min) / delta);   % Quantization index
x_quantized = q_level * delta + x_min;          % Quantized output

% C. PCM encoding (serial bitstream)
bin_str = dec2bin(q_level, n_bits);             % Binary representation of quantized levels
serial_bits = reshape(bin_str', 1, []);         % Serial bit sequence
bit_duration = (1/f_s) / n_bits;                % Bit duration
t_serial = 0:bit_duration:(length(serial_bits)*bit_duration)-bit_duration; 
serial_waveform = serial_bits - '0';            % Convert to numeric waveform (0/1)

% D. Signal reconstruction (decoder output)
[b, a] = butter(2, 0.1);                        % Low-pass filter design
x_reconstructed = filtfilt(b, a, interp1(t_s, x_quantized, t, 'previous'));

%% 3. Waveform Visualization

figure('Name', 'PCM Experiment Waveforms', 'Color', 'w');

% 1. Original analog message signal
subplot(4,1,1);
plot(t, x_analog, 'b', 'LineWidth', 1.5);
title('1. Input: Analog Message Signal');
ylabel('Amplitude (V)');
grid on;
ylim([-1.5 1.5]);

% 2. PCM modulator output (serial bitstream)
subplot(4,1,2);
stairs(t_serial, serial_waveform, 'k', 'LineWidth', 1.2);
title('2. Modulator Output: Serial PCM Data Stream');
ylabel('Logic Level');
ylim([-0.2 1.2]);
grid on;
xlim([0 0.5]);  % Zoomed view for clarity

% 3. Decoder output (quantized staircase signal)
subplot(4,1,3);
stairs(t_s, x_quantized, 'r', 'LineWidth', 1.5);
title('3. Decoder Output: Quantized (Staircase) Output');
ylabel('Amplitude (V)');
grid on;
ylim([-1.5 1.5]);

% 4. Final reconstructed signal after filtering
subplot(4,1,4);
plot(t, x_reconstructed, 'g', 'LineWidth', 1.5);
title('4. Final Output: Reconstructed Signal');
xlabel('Time (s)');
ylabel('Amplitude (V)');
grid on;
ylim([-1.5 1.5]);