clc; clear ; close all;

%% 1.User Input
disp("------------------------------");
disp("    Step Response Generator   ");
disp("------------------------------");

% The input function pauses code until user types a vector
% Example input to try : [1, 0.5, 0.25, 0.125]
h = input("Enter the Impulse Response vector h[n] (e.g., [1 2 3]):");

%% 2. Calculation
% Method 1: Convolution with a Unit Step (The slow , formal way)
%u = ones(size(h));
% s = conv(h,u);

% Method 2: Cumulative Sum(The Fast , efficient way)
% Since Step is the integral of Impulse ,we just accumulate the values.
s = cumsum(h);

%% 3. Define Time axis
N = length(h);
n_axis = 0 : N-1;

%% 4.Visualization 
figure("Name","Impulse to step Response","Color","w");

%Plot A:The Impulse Response (What you entered)
subplot(2,1,1);
stem(n_axis,h,"filled","LineWidth",2,"MarkerSize",8,"Color","b");
grid on;
title("User input:Impulse  Response h[n] ");
xlabel("Time index(n)");ylabel("Amplitude");
xlim([-0.5 N-0.5]);

%Plot B : The Calculated Step Response
subplot(2,1,2);
stem(n_axis,s,"filled","LineWidth",2,"MarkerSize",8,"Color","r");
grid on;
title("Calculated : Step Response s[n] = \Sigma h[k]");
xlabel("Time Index(n)");ylabel("Amplitude");
xlim([-0.5 N-0.5]);

%% 5. Display Result 
disp(" ");
disp("Calculated Step Response values:");
disp(s);