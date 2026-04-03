clc;clear;close all;

%% 1.Define Symbolic variables
% n = Time sample index
% z = Complex frequency variable
% a = Constant (for exponential decay)
% w = frequency (for sine/cosine)
syms n z a w

%% 2.Example A:Unit step function u[n]
% Mathematical definition: 1 for n>=0
x1=1;
X1=ztrans(x1,n,z);

disp('---1.Unit step function---');
disp('Signal:u[n]');
disp('Z-Transform X(z):')
pretty(X1);

%% 2.Example B:Exponential Function a^n
% Mathematical Definition :a^n*u[n]
x2 = a^n;
X2 = ztrans(x2,n,z);
disp('---2.Exponential Function---');
disp('Signal:a^n*u[n]');
disp('z_transform X(z):');
pretty(X2);

%% 3.Example C:Sinusoidal Function 
%Mathematical definition : sin(w*n)*u[n]
x3 = sin(w*n);
X3 = ztrans(x3,n,z);
disp("---3.Sinusoidal Function---");
disp("Signal: sin(wn)*u[n]");
disp("Z-Transform X(z):");
pretty(X3);

%% 4.Example D:Linear Ramp n*u[n]
x4 = n;
X4 = ztrans(x4,n,z);
disp("---Linear Ramp---");
disp("Signal: n*u[n]");
disp("Z-transform X(z):");
pretty(x4);


%% Convert the step function result back to time 
disp("--INVERSE Z-TRANSFORM")
f = z/(z-1);
inverse_signal = iztrans(f,z,n);
disp("Original X(z):Z/(z-1)");
disp("Recoverd Signal x[n]:");
pretty(inverse_signal);