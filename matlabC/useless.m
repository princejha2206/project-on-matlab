% MATLAB Script for Line Coding Techniques
clc; clear; close all;

% 1. Define the input binary sequence
bits = [1 0 1 1 0 0 1 0]; % You can change this sequence
n = length(bits);

% 2. Define signal parameters
bit_rate = 1;             % Bit rate in bps
Tb = 1 / bit_rate;        % Bit duration
fs = 100;                 % Sampling frequency (number of samples per bit)
N = n * fs;               % Total number of samples
t = linspace(0, n*Tb, N); % Time vector for plotting

% 3. Initialize arrays for the different coding schemes
unipolar_nrz = zeros(1, N);
polar_nrz    = zeros(1, N);
manchester   = zeros(1, N);
ami          = zeros(1, N);

% Variable to keep track of previous voltage for AMI inversion
ami_last_voltage = -1;

% 4. Generate the waveforms bit by bit
for i = 1:n
    % Define the sample indices for the current bit
    idx = (i-1)*fs + 1 : i*fs;
    
    % Define sample indices for the first and second half of the bit (for Manchester)
    half_idx1 = (i-1)*fs + 1 : (i-1)*fs + fs/2;
    half_idx2 = (i-1)*fs + fs/2 + 1 : i*fs;

    if bits(i) == 1
        % Unipolar NRZ: High (1)
        unipolar_nrz(idx) = 1;
        
        % Polar NRZ: High (1)
        polar_nrz(idx) = 1;
        
        % Manchester: High-to-Low transition
        manchester(half_idx1) = 1;
        manchester(half_idx2) = -1;
        
        % Bipolar AMI: Alternate between +1 and -1
        ami_last_voltage = -ami_last_voltage;
        ami(idx) = ami_last_voltage;
        
    else % If the bit is 0
        % Unipolar NRZ: Low (0)
        unipolar_nrz(idx) = 0;
        
        % Polar NRZ: Low (-1)
        polar_nrz(idx) = -1;
        
        % Manchester: Low-to-High transition
        manchester(half_idx1) = -1;
        manchester(half_idx2) = 1;
        
        % Bipolar AMI: Zero voltage
        ami(idx) = 0;
    end
end

% 5. Plotting the waveforms
figure('Name', 'Line Coding Schemes', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);

% Unipolar NRZ Plot
subplot(4, 1, 1);
plot(t, unipolar_nrz, 'b', 'LineWidth', 2);
axis([0 n*Tb -1.5 1.5]);
title('Unipolar NRZ');
grid on;

% Polar NRZ Plot
subplot(4, 1, 2);
plot(t, polar_nrz, 'r', 'LineWidth', 2);
axis([0 n*Tb -1.5 1.5]);
title('Polar NRZ');
grid on;

% Manchester Plot
subplot(4, 1, 3);
plot(t, manchester, 'g', 'LineWidth', 2);
axis([0 n*Tb -1.5 1.5]);
title('Manchester Coding');
grid on;

% Bipolar AMI Plot
subplot(4, 1, 4);
plot(t, ami, 'm', 'LineWidth', 2);
axis([0 n*Tb -1.5 1.5]);
title('Bipolar AMI');
xlabel('Time (s)');
grid on;