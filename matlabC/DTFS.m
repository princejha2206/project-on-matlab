clc; clear; close all;

%% 1.Define the Signal (one period)
N=10;    % Fundamental period
n=0:N-1; % Time index for one period

% Create a Rectangular Pulse : is followed by 0s
% x[n] = {1,1,1,1,0,0,0,0,0,0}
L=4;
x=[ones(1,L), zeros(1,N-L)];

%% 2. Evaluate DTFS Coefficients (a_k)
% We implement the formula : a_k = (1/N) * sum( x[n]*exp(-j*2*pi*k*n/N))
k_vec = 0:N-1;  %Harmonic indices
a = zeros(1,N); % Initialize array for coefficients

for k = 0 : N-1
    %Create the complex exponential basis for this k
    basis = exp(-1j * 2*pi*k*n/N);

    %Perform the dot product (summation)
    a(k+1) = (1/N) * sum(x.*basis);
end

%% 3. Extract Magnitude and phase
mag_a = abs(a);      % Magnitude |a_k|
phase_a = angle(a);  % Phase in Radians

% CLEANUP : Remove phase noise
% If magnitude is tiny (near 0) ,phase calculation is garbage noise
% We force phase to 0 where magnitude is negligible
phase_a(mag_a < 1e-10) = 0;

%% 4. VISUALIZATION
figure("Name","DTFS Analysis","Color","w");

% plot 1: The Time Domain Signal
subplot(3,1,1);
stem(n,x,"filled","LineWidth",2,"MarkerSize",8);
title(["Discrete Periodic Signal x[n] (Period N =" num2str(N) ")"]);
xlabel("Time Index(n)"); ylabel("Amplitude");
grid on; axis([-1 N -0.2 1.2]);

% Plot 2 : Magnitude Spectrum
subplot(3,1,2);
stem(k_vec,mag_a,"filled","r","LineWidth",2,"MarkerSize",8);
title("DTFS Magnitude Spectrum |a_k|");
xlabel("Harmonic index (k)");ylabel("Magnitude");
grid on; xlim([-0.5 N-0.5]);

%Plot 3: Phase Spectrum
subplot(3,1,3);
stem(k_vec,phase_a,"filled","g","LineWidth",2,"MarkerSize",8);
title("DTFS Phase Spectrum \angle a_k (Radians)");
xlabel("Harmonic Index(k)"); ylabel("Phase (rad)");
grid on; xlim([-0.5 N-0.5]);
yticks([-pi -pi/2 0 pi/2 pi]);
yticklabels({"-\pi","-\pi/2" , "0" , "\pi/2" ,"\pi"});

%% 5. Display Values
disp("Harmonic Coefficients (a_k):");
disp(table(k_vec', mag_a', phase_a',"VariableNames",{"K","Magnitude","Phase_rad"}));