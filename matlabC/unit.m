clc; clear all; close all;

t=-2:0.01:5;

%% Unit stem funtion u(t)
u = t>=0;

%% Unit Impulse funtion 
delta = abs(t)<0.005;

%% Unit ramp function r(t)
r=t.*(t>=0);

%% Parabolic function P(t)
p=0.5*(t.^2).*(t>=0);

%% Exponential Function e(t)
a=1; %decay
ex = exp(-a * t);

%% Sinusoidal signal x(t)
A=2; %amplitude
f=1; %frequency(1Hz)
s=A*sin(2*pi*f*t);

%% Plotting
figure('Name','Standard','Color','w');

%1 Unit step
subplot(3,2,1);
plot(t,u,'LineWidth',2,'Color','b');
axis([-2 5 -0.2 1.2]);grid on;
title('Unit Step u(t)');

%2 Unit Impulse 
subplot(3,2,2);

stem(t(1:10:end),delta(1:10:end),"LineWidth",2,'Color','r','Marker','none');
axis([-2 5 -0.2 1.2]);grid on;
title('Unit Impulse \delta(t)');

%3 Unit ramp
subplot(3,2,3);
plot(t,r,'LineWidth',2,'Color','g');
axis([-2 5 -1 6]);grid on;
title('Unit Ramp r(t)');

% 4. Parabolic
subplot(3, 2, 4);
plot(t, p, 'LineWidth', 2, 'Color', 'm');
axis([-2 5 -1 10]); grid on;
title('Parabolic p(t) = t^2/2');

% 5. Exponential
subplot(3, 2, 5);
plot(t, ex, 'LineWidth', 2, 'Color', 'k');
axis([-2 5 -0.2 8]); grid on;
title('Exponential e^{-t}');

% 6. Sinusoidal
subplot(3, 2, 6);
plot(t, s, 'LineWidth', 2, 'Color', 'c');
axis([-2 5 -3 3]); grid on;
title('Sinusoidal A*sin(2\pi ft)');