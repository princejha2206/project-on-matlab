clc; clear; close all;

%% 1. Signal Parameters
f = 2;  % Frequency = 2Hz (2 cycle per second )
A = 5;  % Amplitude = 5 volts
Fs = 1000; % Sampling Frequency (High resolution)
T = 2; % Duration in seconds
t = 0 : 1/Fs : T; %Time vector

%% 2. Generate Signals

% A. Sinusoidal Signal 
% Standard Math : A*sin(2*pi*f*t)
y_sine = A*sin(2*pi*f*t);

% B. Square Wave
% Uses "square" function . Input must be angular frequency (2*pi*f*t)
y_square = A*square(2*pi*f*t);

% C. Triangular Wave
% User "sawtooth" function
% The second argument "0.5" places the peak in the middle (Triangle).
% If the second argument is 1, it becomes a pure sawtooth ramp.
y_tri = A*sawtooth(2*pi*f*t,0.5);

%% 3. Visualization
figure('Name', 'Signal Generation', 'Color', 'w');

% Plot Sine
subplot(3, 1, 1);
plot(t, y_sine, 'b', 'LineWidth', 2);
title(['Sinusoidal Signal (f = ' num2str(f) ' Hz)']);
ylabel('Amplitude'); grid on; axis([0 T -A-1 A+1]);

% Plot Square
subplot(3, 1, 2);
plot(t, y_square, 'r', 'LineWidth', 2);
title('Square Wave');
ylabel('Amplitude'); grid on; axis([0 T -A-1 A+1]);

% Plot Triangle
subplot(3, 1, 3);
plot(t, y_tri, 'g', 'LineWidth', 2);
title('Triangular Wave (Symmetric Sawtooth)');
xlabel('Time (s)'); ylabel('Amplitude'); 
grid on; axis([0 T -A-1 A+1]);