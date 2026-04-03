%% 1. Define the sequencs
% Sequence x[n]:input
x=[1,2,3,1];
nx=0:3;

%Sequence h[n]:Impulse Response
h=[1,2,1,-1];
nh=0:3;

%% 2 Perform Convolution
y=conv(x,h);

%% 3. Define the time axis for output 
ny_start = nx(1) + nh(1);
ny_end = nx(end) + nh(end);
ny= ny_start : ny_end;

%% 4. Visualization (Plotting)
figure('Name',"Linear Convolution",'Color','w');

%Plot Input x[n]
subplot(3,1,1);
stem(nx,x,'Filled','LineWidth',2,'MarkerSize',6);
grid on;axis([0 8 -2 5]);
title('Input Sequence x[n]');
ylabel('Amplitude');

%Plot impulse Response h[n]
subplot(3,1,2);
stem(nh,h,"filled","LineWidth",2,'MarkerSize',8,'Color','r');
grid on; axis([0 8 -2 5]);
title("Impulse Response h[n]");
ylabel("Amplitude");

%Plot Convolution Result y[n]
subplot(3,1,3);
stem(ny,y,"filled",'LineWidth',2,'MarkerSize',8,'Color','g');
grid on; axis([0 8 -2 10]);
title("Convolution sum y[n]=x[n]*h[n]");
xlabel("Time Index (n)");
ylabel("Amplitude");

% Display the numerical result in Command Window
disp('Resulting Sequence y[n]:');
disp(y)