clc;
clear all;
close all;

%% 1. Parameters Setup
% These values are chosen to make the graph look like your DSO screen
Fs = 10000;          % Sampling frequency (samples per second)
Tb = 0.01;           % Time duration of one bit (Bit period)
f1 = 1000;           % Frequency for Logic '1' (Mark Frequency - High)
f2 = 500;            % Frequency for Logic '0' (Space Frequency - Low)
N = 8;               % Number of bits to transmit
t = 0:1/Fs:Tb-(1/Fs); % Time vector for one bit duration

%% 2. Data Generation (Binary Input)
% Generating random binary data (e.g., [1 0 1 1 0...])
data_bits = randi([0, 1], 1, N); 

% Creating the digital signal for plotting
digital_signal = [];
for i = 1:N
    if data_bits(i) == 1
        digital_signal = [digital_signal ones(1, length(t))];
    else
        digital_signal = [digital_signal zeros(1, length(t))];
    end
end

%% 3. FSK Modulation (The Transmitter)
% Loop through bits and generate corresponding sine waves
mod_signal = [];
for i = 1:N
    if data_bits(i) == 1
        % If bit is 1, generate High Frequency (f1)
        wave = sin(2*pi*f1*t); 
    else
        % If bit is 0, generate Low Frequency (f2)
        wave = sin(2*pi*f2*t);
    end
    mod_signal = [mod_signal wave];
end

%% 4. FSK Demodulation (The Receiver)
% Using Coherent Detection (Correlation method)
demod_bits = [];
for i = 1:N
    % Extract the portion of the signal corresponding to current bit
    segment = mod_signal((i-1)*length(t)+1 : i*length(t));
    
    % Correlate with carrier frequencies
    x1 = sum(segment .* sin(2*pi*f1*t));
    x2 = sum(segment .* sin(2*pi*f2*t));
    
    % Compare the results (Decision Device/Comparator)
    if x1 > x2
        demod_bits = [demod_bits 1];
    else
        demod_bits = [demod_bits 0];
    end
end

% Creating the demodulated signal for plotting
rx_signal = [];
for i = 1:N
    if demod_bits(i) == 1
        rx_signal = [rx_signal ones(1, length(t))];
    else
        rx_signal = [rx_signal zeros(1, length(t))];
    end
end

%% 5. Visualization (Plotting Results)
full_time = 0:1/Fs:(N*Tb)-(1/Fs); % Total time vector

figure('Name', 'FSK Modulation & Demodulation Experiment');

% Plot 1: Original Digital Data
subplot(3,1,1);
plot(full_time, digital_signal, 'LineWidth', 2);
title('Original Digital Data (Binary Input)');
xlabel('Time (s)'); ylabel('Amplitude');
ylim([-0.5 1.5]); grid on;

% Plot 2: FSK Modulated Signal (What you see on DSO Channel 1)
subplot(3,1,2);
plot(full_time, mod_signal, 'b');
title('FSK Modulated Signal');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

% Plot 3: Demodulated Data (What you see on DSO Channel 2)
subplot(3,1,3);
plot(full_time, rx_signal, 'r', 'LineWidth', 2);
title('Demodulated / Recovered Data');
xlabel('Time (s)'); ylabel('Amplitude');
ylim([-0.5 1.5]); grid on;