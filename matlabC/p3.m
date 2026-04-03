clc;
clear;
close all;

%% 1. SYSTEM PARAMETERS (Based on your Observation)
fc = 153392;          % Carrier Frequency: 153.392 kHz (From your DSO Image)
fs = 20 * fc;         % Sampling Frequency (high enough to capture the wave)
bit_rate = 25000;     % Bit Rate (approximate for visualization)
N = 10;               % Number of bits to transmit
data_bits = [1 0 1 1 0 1 0 0 1 0]; % Arbitrary binary data

%% 2. GENERATE SIGNALS
% Time duration for one bit
Tb = 1 / bit_rate;
t = 0 : 1/fs : (N*Tb) - 1/fs; % Total time vector

% Create the Digital Message Signal (Square Wave)
message_signal = zeros(1, length(t));
for i = 1:N
    % Create a square pulse for each bit
    start_idx = (i-1) * (length(t)/N) + 1;
    end_idx = i * (length(t)/N);
    if data_bits(i) == 1
        message_signal(start_idx:end_idx) = 1;
    else
        message_signal(start_idx:end_idx) = -1; % Bipolar NRZ for BPSK
    end
end

% Create the Carrier Signal (Sine Wave)
carrier = sin(2 * pi * fc * t);

%% 3. BPSK MODULATION
% Multiply Message with Carrier (180 degree phase shift logic)
% Logic 1 -> +Sine, Logic 0 -> -Sine (Inverted)
bpsk_signal = message_signal .* carrier;

% Add slight noise to match real DSO observation (Optional Realism)
bpsk_noisy = awgn(bpsk_signal, 30); 

%% 4. BPSK DEMODULATION (Receiver Side)
% Coherent Detection: Multiply received signal with local carrier
demod_mult = bpsk_noisy .* carrier;

% Low Pass Filter (to remove high frequency carrier components)
[b, a] = butter(5, (2*bit_rate)/fs); % 5th order Butterworth filter
demod_filtered = filtfilt(b, a, demod_mult);

% Comparator (Squaring Circuit to recover bits)
recovered_signal = zeros(1, length(t));
recovered_signal(demod_filtered > 0) = 1;  % Threshold at 0
recovered_signal(demod_filtered <= 0) = 0; % Convert back to 0/1 logic

% Adjust original message to 0/1 for plotting comparison
message_plot = (message_signal + 1) / 2; 

%% 5. PLOTTING THE RESULTS
figure('Name', 'BPSK Experiment Simulation', 'Color', 'white');

% Plot 1: Binary Data (Message)
subplot(4,1,1);
plot(t*1000, message_plot, 'LineWidth', 2, 'Color', 'b');
grid on;
title('1. Binary Message Signal (Data Input)');
ylim([-0.5 1.5]);
ylabel('Amplitude (V)');

% Plot 2: Carrier Signal
subplot(4,1,2);
plot(t(1:500)*1000, carrier(1:500), 'r'); % Zoomed in to see sine wave
grid on;
title(['2. Carrier Signal (Freq: ' num2str(fc/1000) ' kHz) - Zoomed View']);
ylabel('Amplitude (V)');

% Plot 3: BPSK Modulated Signal
subplot(4,1,3);
plot(t*1000, bpsk_noisy, 'Color', [0.85 0.65 0.13]); % Yellow-ish color like your DSO
grid on;
title('3. BPSK Modulated Signal (DSO Output)');
ylabel('Amplitude (V)');
xlabel('Time (ms)');

% Plot 4: Demodulated Output
subplot(4,1,4);
plot(t*1000, recovered_signal, 'LineWidth', 2, 'Color', 'm');
grid on;
title('4. Demodulated / Recovered Data');
ylim([-0.5 1.5]);
xlabel('Time (ms)');