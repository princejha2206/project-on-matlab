% PCM Simulation for Laser-Link Jukebox
fs = 8000;              % Sampling frequency (8kHz for voice/basic audio)
t = 0:1/fs:0.02;        % Time vector (20ms snippet)
f_signal = 440;         % Input signal frequency (440Hz - A4 note)
x = sin(2*pi*f_signal*t); % Analog Input Signal

% 1. Sampling & Quantization (8-bit PCM)
n_bits = 8;
levels = 2^n_bits;
x_quant = round((x + 1) * (levels - 1) / 2); % Map to 0-255

% 2. Decimal to Binary (Encoding)
x_bin = dec2bin(x_quant, n_bits);

% Visualization
subplot(2,1,1);
plot(t, x, 'b', 'LineWidth', 1.5); hold on;
stem(t, (x_quant / (levels/2)) - 1, 'r--');
title('Analog Signal vs. PCM Samples');
legend('Original', 'Sampled');

subplot(2,1,2);
stairs(t(1:20), x_quant(1:20), 'Color', [0 .5 0], 'LineWidth', 2);
title('Quantized Levels (Digital Pulse Representation)');
xlabel('Time (s)');