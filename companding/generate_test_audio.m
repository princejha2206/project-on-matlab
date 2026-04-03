%% =========================================================
%  generate_test_audio.m
%  Generates a realistic speech-like signal and saves it as
%  'speech.wav' — ready to use with companding_wav_test.m
%
%  Run this ONCE to create the file, then run companding_wav_test.m
%% =========================================================

clear; clc;

Fs      = 8000;     % Telephony sample rate (Hz)
dur     = 4.0;      % Duration (seconds)
t       = (0 : 1/Fs : dur - 1/Fs)';

fprintf('Generating speech-like test signal (%g s @ %d Hz)...\n', dur, Fs);

%% ── 1. Voiced speech simulation ──────────────────────────
%  Real speech = pitch (glottal pulses) × vocal tract filter
%  We model this with a pulse train through a resonant filter.

pitch_hz  = 120;                         % typical male pitch
pulse_t   = mod(t, 1/pitch_hz);          % sawtooth (glottal waveform)
glottal   = max(0, 1 - pitch_hz * pulse_t);  % triangular pulse train

% Vocal-tract resonances (formants) for vowel-like quality
% Formant frequencies approximate /a/ sound
f1 = 800;   bw1 = 120;
f2 = 1200;  bw2 = 180;
f3 = 2800;  bw3 = 300;

% Bandpass filter each formant
voiced = zeros(size(t));
for [fc, bw] = [f1 bw1; f2 bw2; f3 bw3]'
    [b, a] = butter(2, [(fc-bw/2) (fc+bw/2)] / (Fs/2), 'bandpass');
    voiced = voiced + filter(b, a, glottal);
end

%% ── 2. Unvoiced speech simulation ────────────────────────
%  Fricative sounds (/s/, /f/) = shaped noise bursts
rng(42);
noise      = randn(size(t));
[b, a]     = butter(3, [3000 3800] / (Fs/2), 'bandpass');
fricative  = filter(b, a, noise);

%% ── 3. Amplitude envelope (syllable rhythm) ─────────────
%  Create a natural on/off pattern mimicking syllables at ~4 Hz
syll_rate  = 4.0;                        % syllables/second
env_base   = 0.5 + 0.5 * sin(2*pi * syll_rate * t);
env_smooth = max(0, env_base) .^ 2;      % non-negative, rounded

% Pause at a few points (natural inter-syllable gaps)
env_smooth(t > 0.8  & t < 1.0)  = 0.04;
env_smooth(t > 1.9  & t < 2.1)  = 0.04;
env_smooth(t > 2.95 & t < 3.15) = 0.04;

%% ── 4. Mix voiced + unvoiced ─────────────────────────────
unvoiced_gate = (t > 0.35 & t < 0.55) | ...   % /s/ burst 1
                (t > 1.5  & t < 1.65) | ...   % /f/ burst
                (t > 2.5  & t < 2.65);         % /sh/ burst

signal = env_smooth .* (0.85 * voiced + 0.5 * fricative .* unvoiced_gate);

%% ── 5. Pitch variation (natural intonation) ─────────────
%  Slightly modulate pitch over time for naturalness
pitch_mod = 1 + 0.08 * sin(2*pi * 0.4 * t);   % ±8 Hz drift
t_mod     = cumsum(pitch_mod) / Fs;
glottal2  = max(0, 1 - 120 * mod(t_mod, 1/120));
voiced2   = zeros(size(t));
for [fc, bw] = [f1 bw1; f2 bw2; f3 bw3]'
    [b, a]  = butter(2, [(fc-bw/2) (fc+bw/2)] / (Fs/2), 'bandpass');
    voiced2 = voiced2 + filter(b, a, glottal2);
end
signal = 0.6*signal + 0.4*(env_smooth .* voiced2);

%% ── 6. Add slight room ambience (short reverb) ──────────
rev_len  = round(0.03 * Fs);             % 30 ms tail
rev_ir   = exp(-linspace(0, 5, rev_len)') .* randn(rev_len, 1);
rev_ir   = rev_ir / max(abs(rev_ir));
reverb   = conv(signal, rev_ir * 0.08);
signal   = signal + reverb(1:numel(signal));

%% ── 7. Normalise & save ──────────────────────────────────
signal = signal / max(abs(signal)) * 0.95;   % normalise to 95% FS
signal = signal * 0.9;                        % slight headroom

audiowrite('speech.wav', signal, Fs);
fprintf('Saved: speech.wav  (%d samples, %.1f s)\n\n', numel(signal), dur);

%% ── 8. Quick preview plot ────────────────────────────────
figure('Name','Generated Test Signal','Color','w','Position',[100 100 900 350]);

subplot(2,1,1)
time_axis = (0:numel(signal)-1) / Fs;
plot(time_axis, signal, 'Color',[0.2 0.45 0.7], 'LineWidth', 0.8);
xlim([0 dur]); ylim([-1.05 1.05]);
title('Speech-Like Test Signal (time domain)', 'FontSize', 13);
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(2,1,2)
N_fft  = 1024;
f_axis = (0:N_fft/2) * Fs / N_fft;
Pxx    = abs(fft(signal(1:N_fft), N_fft)).^2;
plot(f_axis, 10*log10(Pxx(1:N_fft/2+1) + 1e-12), ...
     'Color',[0.7 0.3 0.2], 'LineWidth', 1.2);
xlim([0 Fs/2]); grid on;
title('Spectrum', 'FontSize', 13);
xlabel('Frequency (Hz)'); ylabel('Power (dB)');

sgtitle('Generated Audio for Companding Test', 'FontSize', 15, 'FontWeight', 'bold');

fprintf('Now run:  companding_wav_test\n');
fprintf('(Make sure speech.wav and companding_wav_test.m are in the same folder)\n');
