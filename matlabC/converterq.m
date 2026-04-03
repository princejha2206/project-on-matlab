t = 0:0.0001:1;              % High-resolution time vector
x = sin(2*pi*50*t);          % Analog signal (50 Hz sine wave)
fs = 200;                    % Sampling frequency (must be ≥ 2*fmax)
ts = 0:1/fs:1;               % Sampled time vector
xs = sin(2*pi*50*ts);        % Sampled signal
n_bits = 3;                  % Number of quantization bits
L = 2^n_bits;                % Number of levels
x_min = min(xs);
x_max = max(xs);
q_levels = linspace(x_min, x_max, L);   % Quantization levels
xq = interp1(q_levels, q_levels, xs, 'nearest');  % Quantized signal
figure;
subplot(3,1,1); plot(t, x); title('Original Analog Signal');
subplot(3,1,2); stem(ts, xs); title('Sampled Signal');
subplot(3,1,3); stem(ts, xq); title('Quantized Signal');