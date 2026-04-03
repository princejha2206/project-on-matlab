clc; clear ; close all;

%% 1.Define Symbolic Variables
syms t k T
%Define parameters 
T_val = 2;           % Period = 2 sec
w0_val = 2*pi/T_val; % Fundamental Frequency

%% 2.Define the Signal over One Period 
% Let's define a rectangular pulse of width 1 centered at 0
% x(t) =1 for -0.5 < t <0.5, else 0 within the period [-1 , 1]
% ( This is effectively a Square Wave )
x = heaviside(t+0.5) - heaviside(t-0.5);

%% 3.Compute DC Component (a0) separately 
% a0 is the average value of the signal over one period
% a0 = (1/T) * integral(x)
a0_sym = (1/T) * int(x, t, -T/2, T/2);

% Substitute T value
a0_val = double(subs(a0_sym,T,T_val));

%% 4.Compute Harmonic Coefficients (ak) 
% ak = (1/T)*integral(x*exp(-j*k*w0*t))
term = x*exp(-1j*k*(2*pi/T)*t);
ak_sym =(1/T)*int(term,t,-T/2,T/2);

%Simplify the symbolic expression (Should look like a sinc Function)
ak_simplified = simplify(ak_sym);

disp("---Symbolic Result for a_k ---");
pretty(ak_simplified);

%% 5.Evalute Numerical Values for Plotting
K_harmonics = -10:10; % Range of harmonics to plot
ak_values = zeros(size(K_harmonics));

for i = 1:length(K_harmonics)
    k_current = K_harmonics(i);

    if k_current == 0
        % Use the separately computed a0 for k=0
        ak_values(i) = a0_val;
    else
    % Substitute k and T into the symbolic formula
    % We use 'limit' or simple substitution
    % Since we solved the integral generically ,we just plug in numbers
        val = subs(ak_simplified,{k,T},{k_current,T_val});
        ak_values(i) = double(val);
    end
end

%% 6.Visualization (Magnitude and phase spectra)
figure("Name",'CTFS Coefficients','Color','w');

% Plot Magnitude
subplot(2, 1, 1);
stem(K_harmonics, abs(ak_values), 'filled', 'LineWidth', 2, 'MarkerSize', 8);
title('Magnitude Spectrum |a_k| (Sinc Function Pattern)');
xlabel('Harmonic Index k'); ylabel('|a_k|');
grid on; axis([-10 10 0 0.6]);

% Plot Phase
subplot(2, 1, 2);
stem(K_harmonics, angle(ak_values), 'filled', 'r', 'LineWidth', 2);
title('Phase Spectrum \angle a_k');
xlabel('Harmonic Index k'); ylabel('Phase (rad)');
grid on; axis([-10 10 -3.5 3.5]);

% Display explicit values 
disp("Calculated Coefficients (k = -2 to 2):");
disp(ak_values(K_harmonics >= -2 & K_harmonics <= 2));