clc;clear;close all;

%% 1.System Parameters
fm = 10; % Maximum frequency of the signal (10Hz)
fs = 30; % Sampling Frequency (Nyquist is 20Hz , so 30hz is safe)
Ts = 1/fs; % Sampling interval 
Duration = 1; % Duration of signal in second 

%% 2.Simulate "Continuous" Signal (High Resolution)
fs_analog = 1000; %High sampling rate to mimic analog/continuous 
t_analog = 0 : 1/fs_analog : Duration;
%Signal:A mix of 5Hz & 10Hz components
x_analog = cos(2*pi*5*t_analog) + 0.5*cos(2*pi*10*t_analog);

%% 3.Perform ideal Sampling 
t_sample = 0 : Ts : Duration;
x_sample = cos(2*pi*5*t_sample) + 0.5*cos(2*pi*10*t_sample);

%% 4.Frequency Analysis (Fourier transform)
% A.Spectrum of analog signal

L_analog = length(x_analog);
X_analog = fftshift(fft(x_analog));
f_axis_analog = linspace(-fs_analog/2,fs_analog/2,L_analog);
Mag_analog = abs(X_analog)/L_analog;

% B.Spectrum of sampled signal 
% Ideally sampled signal spectrum is periodic . We simulate this by 
%taking the FFt of the samples and plotting it over multiple periods
L_sample = length(x_sample);
X_sample = fftshift(fft(x_sample));
Mag_sample = abs(X_sample)/L_sample;
f_axis_sample = linspace(-fs/2,fs/2,L_sample);

%% 5. VISULAIZATION 
figure("Name","Sampling Theorem & spectra","Color",'w');

% --- TIME DOMAIN PLOTS ---
subplot(3,1,1);
plot(t_analog,x_analog,'b','LineWidth',1.5);hold on;
stem(t_sample,x_sample,'r','LineWidth',1.5,"MarkerFaceColor","r");
legend("Continuous Signal x(t)","Sampled signal x(nT)");
title(['Time Domain : Signal vs samples (f_s= ' num2str(fs) 'Hz)']);
xlabel("Time(s)");ylabel("Amplitude");
grid on; axis([0 0.5 -2 2]);

%---Frequency Domain : Analog ---
subplot(3,1,2);
plot(f_axis_analog,Mag_analog,'b','LineWidth',2);
title("Spectrum of Original analog Signal X(f)");
xlabel("Frequency(Hz)");ylabel("|X(f)|");
xlim([-50 50]); grid on;

%Annotate the base frequencies
text(5,0.4,'5Hz'); text(10,0.2,'10Hz');

% ---Frequency Domain: Sampled (Showing Replicas) ---
subplot(3,1,3);
hold on;
% Plot  Base Spectrum (Center)
stem(f_axis_sample,Mag_sample,'r','LineWidth',2,'DisplayName','Baseband');
% Plot Left Replica (Shifted by -fs)
stem(f_axis_sample-fs,Mag_sample,"k--",'LineWidth',1,'DisplayName','Replica at -f_s');
% Plot Right replica (Shifted by +fs)
stem(f_axis_sample + fs,Mag_sample,'k--','LineWidth',1,'DisplayName','Replica at +f_s');

title("Spectrum of ideally Sampled Signal (Periodic Repetitions");
xlabel("Frequency(Hz)"); ylabel("Magnitude");
legend("show");
grid on;
xlim([-50 50]);
% Draw line to show Sampling Frequency centres
xline(fs,'g:','f_s');
xline(-fs,'g:','-f_s');