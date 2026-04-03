%% DIGITAL COMPANDING USING A-LAW AND MU-LAW
clear; close all; clc;

%% Generate test signal
fs = 8000;
t = (0:1/fs:0.1)';
x = 0.8*sin(2*pi*300*t) + 0.2*sin(2*pi*800*t) + 0.05*sin(2*pi*2000*t);
x = x / max(abs(x));

%% Parameters
mu = 255;
A  = 87.6;
nbits = 8;
L = 2^nbits;
delta = 2 / L;

%% Mu-Law Compression
y_mu_comp = sign(x) .* log(1 + mu * abs(x)) / log(1 + mu);

%% A-Law Compression
y_a_comp = zeros(size(x));
idx_small = abs(x) <= 1/A;
y_a_comp(idx_small) = sign(x(idx_small)) .* (A * abs(x(idx_small))) / (1 + log(A));
y_a_comp(~idx_small) = sign(x(~idx_small)) .* ...
                       (1 + log(A * abs(x(~idx_small)))) / (1 + log(A));

%% Uniform Quantization
y_mu_comp = max(min(y_mu_comp, 1), -1);
y_a_comp  = max(min(y_a_comp,  1), -1);
y_mu_quant = delta * round(y_mu_comp / delta);
y_a_quant  = delta * round(y_a_comp  / delta);

%% Expansion
x_mu_rec = sign(y_mu_quant) .* (((1 + mu).^abs(y_mu_quant) - 1) / mu);

x_a_rec = zeros(size(y_a_quant));
bound = 1 / (1 + log(A));
idx_small_a = abs(y_a_quant) <= bound;
x_a_rec(idx_small_a) = sign(y_a_quant(idx_small_a)) .* ...
                       (abs(y_a_quant(idx_small_a)) * (1 + log(A)) / A);
x_a_rec(~idx_small_a) = sign(y_a_quant(~idx_small_a)) .* ...
                        (exp(abs(y_a_quant(~idx_small_a)) * (1 + log(A)) - 1) / A);

%% Plots
figure(1);
subplot(3,1,1); plot(t, x); title('Original Normalized Signal'); grid on; axis tight;
subplot(3,1,2); plot(t, x_mu_rec, 'r'); title('Reconstructed - Mu-Law (8-bit)'); grid on; axis tight;
subplot(3,1,3); plot(t, x_a_rec, 'g'); title('Reconstructed - A-Law (8-bit)'); grid on; axis tight;

figure(2);
xx = linspace(-1,1,1000)';
y_mu_curve = sign(xx) .* log(1 + mu * abs(xx)) / log(1 + mu);
y_a_curve = zeros(size(xx));
idx = abs(xx) <= 1/A;
y_a_curve(idx) = sign(xx(idx)) .* (A * abs(xx(idx))) / (1 + log(A));
y_a_curve(~idx) = sign(xx(~idx)) .* (1 + log(A * abs(xx(~idx)))) / (1 + log(A));

plot(xx, y_mu_curve, 'b', 'LineWidth', 2); hold on;
plot(xx, y_a_curve, 'r', 'LineWidth', 2);
plot(xx, xx, 'k--', 'LineWidth', 1.5);
legend('Mu-Law Compressor (mu=255)', 'A-Law Compressor (A=87.6)', ...
       'Linear (no companding)', 'Location', 'southeast');
title('Compander Characteristics');
xlabel('Normalized Input x');
ylabel('Compressed Output y');
grid on; axis([-1 1 -1 1]);

%% Performance
mse_mu = mean((x - x_mu_rec).^2);
mse_a  = mean((x - x_a_rec).^2);
snr_mu = 10 * log10(var(x) / mse_mu);
snr_a  = 10 * log10(var(x) / mse_a);

fprintf('Mu-Law:  MSE = %.6f,  SNR = %.2f dB\n', mse_mu, snr_mu);
fprintf('A-Law :  MSE = %.6f,  SNR = %.2f dB\n', mse_a,  snr_a);