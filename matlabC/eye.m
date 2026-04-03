% Parameters
N = 1e5;              % Number of symbols
M = 2;                % BPSK modulation
sps = 8;              % Samples per symbol
rolloff = 0.25;       % Roll-off factor
span = 10;            % Filter span in symbols

% Generate random data
data = randi([0 M-1], N, 1);
txSig = pskmod(data, M);

% Raised Cosine filter
rcFilter = rcosdesign(rolloff, span, sps, 'sqrt');

% Apply filter (pulse shaping)
txFilt = upfirdn(txSig, rcFilter, sps);

% Eye diagram visualization
eyediagram(txFilt(1:5000), 2*sps);
title('Eye Diagram with RRC Filter (Nyquist Criterion)');