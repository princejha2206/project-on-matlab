clc;clear; close all;

%% 1.Define the sequence(Reference signal) 
x=[1,2,3,4];

%Sequence y: The signal we are comparing
y=[0,1,2,3];

%% 2.Calculate cross-correlation and the lag indices(lags)
[r_xy,lags] = xcorr(x,y);

%% 3.Calculate Auto-Correlation(for comparison)
[r_xx,lags_xx]=xcorr(x,x);

%% 4.Visualization 
figure('Name','Correlation Analysis',"Color",'w');

%Plot input Sequences
subplot(3,1,1);
hold on;
stem(0:3,x,'filled','b','LineWidth',2,'DisplayName','x[n]');
stem(0:3,x,'filled','r','LineWidth',2,'DisplayName','y[n]');
hold off;
grid on;legend;
title("Input Sequences x[n] & y[n]");
xlabel("Time Index n"); ylabel("Amplitude");

%Plot Cross-Correlation
subplot(3,1,2);
stem(lags,r_xy,'filled','k','LineWidth',2);
grid on;
title("Cross-Correlation r_{xy}(Measure of similarity");
xlabel("lag(l)");ylabel("Amplitude");

%Plot Auto-Correlation
subplot(3,1,3);
stem(lags_xx,r_xx,"filled","m",'LineWidth',2);
grid on;
title("Auto-Correlation r_{xx}(Symmetry check)");
xlabel("Lag(l)");ylabel("Amplitude");

%Display Max Correlation lag
[max_val,max_idx]=max(r_xy);
optimal_lag=lags(max_idx);
disp(["The sequence are most similar at lag:",num2str(optimal_lag)]);
