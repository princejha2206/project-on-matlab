% =================================================================
% Experiment: Laplace Transform using Symbolic Math
% =================================================================
clc;
clear all;
close all;

%% 1. Define Symbolic Variables
% We must declare 't' and 's' as symbolic variables before using them
syms t s;

%% 2. Define the Time-Domain Function f(t)
% Replace the equation below with the specific function from your assignment
% MATLAB syntax tips: 
% exp() is e^x, sin() is sine, cos() is cosine, * is multiply, ^ is power
f_t = t^2 + exp(-2*t) * sin(3*t);

%% 3. Compute the Laplace Transform
% Calculate F(s) = L{f(t)}
F_s = laplace(f_t, t, s);

%% 4. Simplify the Result (Optional but recommended)
% This combines fractions and simplifies the algebraic expression
F_s_simplified = simplify(F_s);

%% 5. Display the Results
disp('--------------------------------------------------');
disp('RESULTS: Laplace Transform Calculation');
disp('--------------------------------------------------');

disp('The original time-domain function f(t) is:');
pretty(f_t)

disp('The simplified Laplace Transform F(s) is:');
pretty(F_s_simplified)

disp('--------------------------------------------------');