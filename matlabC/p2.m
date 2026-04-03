% ==============================================================================
% DELTA MODULATION & DEMODULATION ANALYSIS
% Professional Visualization of All Stages
% ==============================================================================
clc;
clear;
close all;

%% --- 1. System Parameters ---
fm = 50;           % Input signal frequency (Hz)
Am = 12;           % Input signal amplitude (V)
fs = 16000;        % Sampling frequency (Hz)
T_duration = 0.04; % Simulation duration (2 cycles)
Delta = 0.8;       % Step size (V)

%% --- 2. Signal Generation ---
t = 0:1/fs:T_duration;
m_t = Am * sin(2*pi*fm*t); % Original Analog Input

%% --- 3. Modulation Loop ---
% Initialize arrays
m_staircase = zeros(1, length(t)); % Accumulator output
bit_stream = zeros(1, length(t));  % Transmitted bits (+1/-1)

for n = 2:length(t)
    % Comparator: If input > current value, send +1, else -1
    if m_t(n-1) >= m_staircase(n-1)
        bit_stream(n) = 1;
        m_staircase(n) = m_staircase(n-1) + Delta;
    else
        bit_stream(n) = -1;
        m_staircase(n) = m_staircase(n-1) - Delta;
    end
end

% --- 4. Visualization (Separate Plots) ---
figure('Name', 'Delta Modulation Stages', 'Color', 'w', 'Position', [100, 50, 800, 900]);

% --- Plot 1: Original Analog Input ---
subplot(3,1,1);
plot(t*1000, m_t, 'b', 'LineWidth', 1.5);
title('1. Original Analog Input Signal');  % Removed m(t)
xlabel('Time (ms)'); 
ylabel('Amplitude (V)');
grid on; axis tight;
ylim([-Am*1.2 Am*1.2]);

% --- Plot 2: Transmitted Digital Bitstream ---
subplot(3,1,2);
stairs(t*1000, bit_stream, 'k', 'LineWidth', 1.2);
title('2. Transmitted Digital Bitstream'); % Removed d(t)
xlabel('Time (ms)'); 
ylabel('Logic Level');
grid on; axis tight;
ylim([-1.5 1.5]);
xlim([0 9]);

% --- Plot 3: Demodulated Staircase Output ---
subplot(3,1,3);
stairs(t*1000, m_staircase, 'r', 'LineWidth', 1.5);
title('3. Demodulated Staircase Output');  % Removed \hat{m}(t)
xlabel('Time (ms)'); 
ylabel('Amplitude (V)');
grid on; axis tight;
ylim([-Am*1.2 Am*1.2]);

% --- Overall Title ---
sgtitle(['Delta Modulation Experiment (50Hz Input, 16kHz Clock)'], 'FontSize', 12, 'FontWeight', 'bold');