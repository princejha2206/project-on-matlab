%% =========================================================
%  companding_wav_test.m
%  Optional: Test companding on a real speech .wav file.
%  Usage: Place a .wav file in the same folder, then run.
%% =========================================================

clear; clc; close all;

%% ── User setting ─────────────────────────────────────────
wav_file = 'speech.wav';      % <-- change to your .wav filename

mu     = 255;
A      = 87.6;
N_bits = 8;

%% ── Load WAV ─────────────────────────────────────────────
if ~isfile(wav_file)
    error(['File "%s" not found.\n' ...
           'Place a .wav file in the same directory and update wav_file.'], wav_file);
end

[x_raw, Fs] = audioread(wav_file);

% Use mono, first 4 seconds maximum
if size(x_raw,2) > 1, x_raw = x_raw(:,1); end
x_raw = x_raw(1 : min(end, 4*Fs));

% Normalise to [-1, +1]
x = x_raw / max(abs(x_raw));

fprintf('Loaded: %s  |  Fs=%d Hz  |  %d samples  (%.2f s)\n', ...
        wav_file, Fs, numel(x), numel(x)/Fs);

%% ── Companding pipeline ──────────────────────────────────
xc_mu = mulaw_compress(x, mu);
xc_a  = alaw_compress(x, A);

xq_p  = uniform_quantise(x,     N_bits);
xq_mc = uniform_quantise(xc_mu, N_bits);
xq_ac = uniform_quantise(xc_a,  N_bits);

xr_mu = mulaw_expand(xq_mc, mu);
xr_a  = alaw_expand(xq_ac,  A);

%% ── SQNR ─────────────────────────────────────────────────
fprintf('\nSQNR on speech signal (%d-bit):\n', N_bits);
fprintf('  Plain PCM : %.2f dB\n', calc_sqnr(x, xq_p));
fprintf('  μ-Law     : %.2f dB\n', calc_sqnr(x, xr_mu));
fprintf('  A-Law     : %.2f dB\n', calc_sqnr(x, xr_a));

%% ── Listen (optional) ────────────────────────────────────
fprintf('\nPlaying original (2 s)...\n');  soundsc(x(1:min(end,2*Fs)),    Fs); pause(2.5)
fprintf('Playing μ-Law output...\n');      soundsc(xr_mu(1:min(end,2*Fs)),Fs); pause(2.5)
fprintf('Playing A-Law output...\n');      soundsc(xr_a(1:min(end,2*Fs)), Fs); pause(2.5)
fprintf('Done.\n')

%% ── Save outputs ─────────────────────────────────────────
audiowrite('output_mulaw.wav',  xr_mu, Fs);
audiowrite('output_alaw.wav',   xr_a,  Fs);
audiowrite('output_plainpcm.wav', xq_p, Fs);
fprintf('Saved: output_mulaw.wav, output_alaw.wav, output_plainpcm.wav\n')
