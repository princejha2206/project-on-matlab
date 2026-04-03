%==========================================================================
% AUDIO MODULATION GUI - Interactive Analysis Tool
%==========================================================================
% Professional GUI for comparing PCM, DPCM, and Delta Modulation
%
% Features:
%   - Load WAV files or generate test signals
%   - Real-time encoding/decoding
%   - Adjustable parameters (bit depth, quantization type, predictor)
%   - Live visualization of signals, errors, and spectra
%   - Comprehensive metrics display
%   - Export capabilities
%
% Usage:
%   main_GUI
%
%==========================================================================

function main_GUI()
    % Create figure
    fig = figure('Name', 'Audio Modulation & Quantization Analysis', ...
        'NumberTitle', 'off', ...
        'Position', [100 100 1400 900], ...
        'MenuBar', 'file', ...
        'ToolBar', 'none', ...
        'HandleVisibility', 'on', ...
        'CloseRequestFcn', @closeGUI);
    
    % =====================================================================
    % SETUP: Create UI components
    % =====================================================================
    
    % Left panel - Controls
    uipanel('Parent', fig, 'Position', [0 0 0.25 1], ...
        'BackgroundColor', [0.95 0.95 0.95], 'BorderType', 'none');
    
    % Signal selection
    y_pos = 0.95;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'SIGNAL SOURCE', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'pushbutton', 'Parent', fig, ...
        'String', 'Load WAV File', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'Callback', @loadWAVFile, 'FontSize', 10);
    
    y_pos = y_pos - 0.05;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'OR Generate Signal:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.05;
    uicontrol('Style', 'popupmenu', 'Parent', fig, ...
        'String', 'Sine Wave|Cosine Wave|Square Wave|Triangle Wave|Multi-tone', ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'Callback', @generateNewSignal, 'Tag', 'signalType');
    
    % Signal parameters
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Frequency (Hz):', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 8, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'edit', 'Parent', fig, ...
        'String', '1000', 'Units', 'normalized', ...
        'Position', [0.14 y_pos-0.02 0.1 0.02], ...
        'Callback', @updateSignal, 'Tag', 'freq', 'FontSize', 8);
    
    y_pos = y_pos - 0.04;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Duration (s):', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 8, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'edit', 'Parent', fig, ...
        'String', '1', 'Units', 'normalized', ...
        'Position', [0.14 y_pos-0.02 0.1 0.02], ...
        'Callback', @updateSignal, 'Tag', 'duration', 'FontSize', 8);
    
    y_pos = y_pos - 0.04;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Amplitude:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 8, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'edit', 'Parent', fig, ...
        'String', '1.0', 'Units', 'normalized', ...
        'Position', [0.14 y_pos-0.02 0.1 0.02], ...
        'Callback', @updateSignal, 'Tag', 'amplitude', 'FontSize', 8);
    
    % =====================================================================
    % ENCODING PARAMETERS
    % =====================================================================
    
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'ENCODING PARAMETERS', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.05;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Bit Depth:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'slider', 'Parent', fig, ...
        'Min', 1, 'Max', 16, 'Value', 8, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.04 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'bitDepth');
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', '8 bits', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.06 0.23 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95], 'Tag', 'bitDepthLabel');
    
    y_pos = y_pos - 0.08;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Quantization Type:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'popupmenu', 'Parent', fig, ...
        'String', 'Uniform|A-law|µ-law', ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.04 0.23 0.03], ...
        'Callback', @updateEncoding, 'Tag', 'quantType');
    
    % DPCM predictor
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'DPCM Predictor α:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'slider', 'Parent', fig, ...
        'Min', 0, 'Max', 1, 'Value', 0.95, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.04 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'predictorAlpha');
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', '0.95', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.06 0.23 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95], 'Tag', 'alphaLabel');
    
    % Delta Mod step size
    y_pos = y_pos - 0.08;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Delta Mod Step Size:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.12 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95]);
    uicontrol('Style', 'slider', 'Parent', fig, ...
        'Min', 0.01, 'Max', 0.5, 'Value', 0.1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.04 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'deltaStepSize');
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', '0.1', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.06 0.23 0.02], ...
        'FontSize', 9, 'BackgroundColor', [0.95 0.95 0.95], 'Tag', 'stepSizeLabel');
    
    % =====================================================================
    % CODEC SELECTION
    % =====================================================================
    
    y_pos = y_pos - 0.08;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'CODECS TO COMPARE', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.04;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'PCM (Linear)', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'enablePCM', 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'DPCM', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'enableDPCM', 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'Delta Modulation', 'Value', 0, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updateEncoding, 'Tag', 'enableDelta', 'BackgroundColor', [0.95 0.95 0.95]);
    
    % =====================================================================
    % VISUALIZATION OPTIONS
    % =====================================================================
    
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'DISPLAY OPTIONS', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.04;
    uicontrol('Style', 'text', 'Parent', fig, ...
        'String', 'Show:', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.02 0.06 0.02], ...
        'FontSize', 8, 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'Time Domain', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updatePlots, 'Tag', 'showTime', 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'Error Signal', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updatePlots, 'Tag', 'showError', 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'Frequency Spectrum', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updatePlots, 'Tag', 'showSpectrum', 'BackgroundColor', [0.95 0.95 0.95]);
    
    y_pos = y_pos - 0.03;
    uicontrol('Style', 'checkbox', 'Parent', fig, ...
        'String', 'Metrics Table', 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.01 y_pos-0.02 0.23 0.02], ...
        'Callback', @updatePlots, 'Tag', 'showMetrics', 'BackgroundColor', [0.95 0.95 0.95]);
    
    % =====================================================================
    % EXPORT & INFO
    % =====================================================================
    
    y_pos = y_pos - 0.06;
    uicontrol('Style', 'pushbutton', 'Parent', fig, ...
        'String', 'Export Results', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'Callback', @exportResults, 'FontSize', 10);
    
    y_pos = y_pos - 0.04;
    uicontrol('Style', 'pushbutton', 'Parent', fig, ...
        'String', 'Help', 'Units', 'normalized', ...
        'Position', [0.01 y_pos-0.03 0.23 0.03], ...
        'Callback', @showHelp, 'FontSize', 10);
    
    % Display area
    uipanel('Parent', fig, 'Position', [0.25 0 0.75 1], ...
        'BackgroundColor', [1 1 1], 'BorderType', 'line');
    
    % Create display area with tabs
    tabgroup = uitabgroup('Parent', fig, 'Position', [0.26 0.01 0.73 0.98]);
    
    % Tab 1: Waveforms
    tab1 = uitab(tabgroup, 'Title', 'Waveforms');
    axes_handle = axes('Parent', tab1);
    set(axes_handle, 'Tag', 'displayAxes');
    
    % Tab 2: Detailed Analysis
    tab2 = uitab(tabgroup, 'Title', 'Analysis');
    axes_handle2 = axes('Parent', tab2);
    set(axes_handle2, 'Tag', 'analysisAxes');
    
    % Tab 3: Comparison
    tab3 = uitab(tabgroup, 'Title', 'Comparison');
    axes_handle3 = axes('Parent', tab3);
    set(axes_handle3, 'Tag', 'comparisonAxes');
    
    % Initialize signal
    updateSignal();
    
    % =====================================================================
    % CALLBACK FUNCTIONS
    % =====================================================================
    
    function loadWAVFile(~, ~)
        [filename, pathname] = uigetfile('*.wav', 'Load WAV File');
        if isequal(filename, 0)
            return;
        end
        
        try
            [signal, fs_loaded] = audioread([pathname, filename]);
            
            % Store in appdata
            setappdata(fig, 'signal', signal);
            setappdata(fig, 'fs', fs_loaded);
            setappdata(fig, 'filename', filename);
            
            % Update display
            updateEncoding();
        catch ME
            errordlg(['Error loading file: ', ME.message]);
        end
    end
    
    function generateNewSignal(hObject, ~)
        updateSignal();
    end
    
    function updateSignal(hObject, ~)
        try
            % Get parameters
            signalTypePopup = findobj(fig, 'Tag', 'signalType');
            signalType = get(signalTypePopup, 'String');
            signalTypeIdx = get(signalTypePopup, 'Value');
            signalType = signalType{signalTypeIdx};
            
            freq = str2double(get(findobj(fig, 'Tag', 'freq'), 'String'));
            duration = str2double(get(findobj(fig, 'Tag', 'duration'), 'String'));
            amplitude = str2double(get(findobj(fig, 'Tag', 'amplitude'), 'String'));
            
            fs = 8000; % Sampling frequency
            t = 0:1/fs:duration-1/fs;
            
            % Generate signal
            switch lower(signalType)
                case 'sine wave'
                    signal = amplitude * sin(2*pi*freq*t);
                case 'cosine wave'
                    signal = amplitude * cos(2*pi*freq*t);
                case 'square wave'
                    signal = amplitude * square(2*pi*freq*t);
                case 'triangle wave'
                    signal = amplitude * sawtooth(2*pi*freq*t, 0.5);
                case 'multi-tone'
                    signal = amplitude/3 * (sin(2*pi*freq*t) + sin(2*pi*freq*1.5*t) + sin(2*pi*freq*2*t));
                otherwise
                    signal = amplitude * sin(2*pi*freq*t);
            end
            
            signal = signal(:); % Column vector
            
            % Store in appdata
            setappdata(fig, 'signal', signal);
            setappdata(fig, 'fs', fs);
            
            % Update encoding
            updateEncoding();
            
        catch ME
            errordlg(['Error generating signal: ', ME.message]);
        end
    end
    
    function updateEncoding(hObject, ~)
        try
            % Get signal
            signal = getappdata(fig, 'signal');
            if isempty(signal)
                return;
            end
            
            fs = getappdata(fig, 'fs');
            if isempty(fs)
                fs = 8000;
            end
            
            % Get parameters
            bitDepth = round(get(findobj(fig, 'Tag', 'bitDepth'), 'Value'));
            set(findobj(fig, 'Tag', 'bitDepthLabel'), 'String', sprintf('%d bits', bitDepth));
            
            quantTypePopup = findobj(fig, 'Tag', 'quantType');
            quantTypeList = get(quantTypePopup, 'String');\n            quantTypeIdx = get(quantTypePopup, 'Value');
            quantType = quantTypeList{quantTypeIdx};
            
            alpha = get(findobj(fig, 'Tag', 'predictorAlpha'), 'Value');
            set(findobj(fig, 'Tag', 'alphaLabel'), 'String', sprintf('%.4f', alpha));
            
            deltaStepSize = get(findobj(fig, 'Tag', 'deltaStepSize'), 'Value');
            set(findobj(fig, 'Tag', 'stepSizeLabel'), 'String', sprintf('%.4f', deltaStepSize));
            
            % Encode
            results = struct();
            
            % PCM
            if get(findobj(fig, 'Tag', 'enablePCM'), 'Value')
                [~, decoded_pcm, ~, metrics_pcm] = pcmCoder.encode(signal, bitDepth, quantType, fs);
                results.pcm.decoded = decoded_pcm;
                results.pcm.metrics = metrics_pcm;
            end
            
            % DPCM
            if get(findobj(fig, 'Tag', 'enableDPCM'), 'Value')
                [~, decoded_dpcm, ~, metrics_dpcm] = dpcmCoder.encode(signal, bitDepth, alpha, quantType, 1);
                results.dpcm.decoded = decoded_dpcm;
                results.dpcm.metrics = metrics_dpcm;
            end
            
            % Delta Modulation
            if get(findobj(fig, 'Tag', 'enableDelta'), 'Value')
                [~, decoded_delta, ~, metrics_delta] = deltaModCoder.encodeFixed(signal, deltaStepSize, fs);
                results.delta.decoded = decoded_delta;
                results.delta.metrics = metrics_delta;
            end
            
            % Store results
            setappdata(fig, 'results', results);
            
            % Update plots
            updatePlots();
            
        catch ME
            errordlg(['Error encoding signal: ', ME.message]);
        end
    end
    
    function updatePlots(hObject, ~)
        try
            signal = getappdata(fig, 'signal');
            results = getappdata(fig, 'results');
            
            if isempty(signal) || isempty(results)
                return;
            end
            
            % Get display options
            showTime = get(findobj(fig, 'Tag', 'showTime'), 'Value');
            showError = get(findobj(fig, 'Tag', 'showError'), 'Value');
            showSpectrum = get(findobj(fig, 'Tag', 'showSpectrum'), 'Value');
            showMetrics = get(findobj(fig, 'Tag', 'showMetrics'), 'Value');
            
            % Plot on display axes
            displayAxes = findobj(fig, 'Tag', 'displayAxes');
            cla(displayAxes);
            
            plotCount = 0;
            if showTime; plotCount = plotCount + 1; end
            if showError; plotCount = plotCount + 1; end
            if showSpectrum; plotCount = plotCount + 1; end
            
            if plotCount == 0
                plotCount = 1;
            end
            
            % Time domain
            if showTime
                subplot(ceil(plotCount/2), 2, 1, 'Parent', displayAxes);
                t_plot = 1:min(1000, length(signal));
                
                plot(t_plot, signal(t_plot), 'b-', 'LineWidth', 1.5);
                hold on;
                if isfield(results, 'pcm') && isfield(results.pcm, 'decoded')
                    plot(t_plot, results.pcm.decoded(t_plot), 'r.', 'MarkerSize', 4);
                end
                if isfield(results, 'dpcm') && isfield(results.dpcm, 'decoded')
                    plot(t_plot, results.dpcm.decoded(t_plot), 'g+', 'MarkerSize', 5);
                end
                if isfield(results, 'delta') && isfield(results.delta, 'decoded')
                    plot(t_plot, results.delta.decoded(t_plot), 'ms', 'MarkerSize', 3);
                end
                
                xlabel('Sample'); ylabel('Amplitude');
                title('Waveforms Comparison');
                legend('Original', 'PCM', 'DPCM', 'Delta');
                grid on;
            end
            
            % Error
            if showError
                subplot(ceil(plotCount/2), 2, 2, 'Parent', displayAxes);
                
                if isfield(results, 'pcm') && isfield(results.pcm, 'decoded')
                    error_pcm = signal - results.pcm.decoded;
                    plot(t_plot, error_pcm(t_plot), 'r-', 'LineWidth', 1);
                    hold on;
                end
                if isfield(results, 'dpcm') && isfield(results.dpcm, 'decoded')
                    error_dpcm = signal - results.dpcm.decoded;
                    plot(t_plot, error_dpcm(t_plot), 'g-', 'LineWidth', 1);
                end
                if isfield(results, 'delta') && isfield(results.delta, 'decoded')
                    error_delta = signal - results.delta.decoded;
                    plot(t_plot, error_delta(t_plot), 'm-', 'LineWidth', 1);
                end
                
                xlabel('Sample'); ylabel('Error');
                title('Quantization Error');
                legend('PCM', 'DPCM', 'Delta');
                grid on;
            end
            
            % Spectrum
            if showSpectrum
                subplot(ceil(plotCount/2), 2, 3, 'Parent', displayAxes);
                N = length(signal);
                freq_axis = 0:1:N-1;
                spec_orig = abs(fft(signal, N));
                
                plot(freq_axis(1:N/2), spec_orig(1:N/2), 'b-', 'LineWidth', 1.5);
                hold on;
                
                if isfield(results, 'pcm') && isfield(results.pcm, 'decoded')
                    spec_pcm = abs(fft(results.pcm.decoded, N));
                    plot(freq_axis(1:N/2), spec_pcm(1:N/2), 'r--', 'LineWidth', 1);
                end
                
                xlabel('Frequency Bin'); ylabel('Magnitude');
                title('Frequency Spectrum');
                legend('Original', 'PCM');
                grid on;
            end
            
            % Metrics table
            if showMetrics
                subplot(ceil(plotCount/2), 2, 4, 'Parent', displayAxes);
                axis off;
                
                metricsText = sprintf('CODEC COMPARISON\n\n');
                
                if isfield(results, 'pcm') && isfield(results.pcm, 'metrics')
                    m = results.pcm.metrics;
                    metricsText = [metricsText, ...
                        sprintf('PCM (%s):\n', m.quantType), ...
                        sprintf('  Bitrate: %d kbps\n', m.bitrate/1000), ...
                        sprintf('  SQNR: %.2f dB\n\n', m.sqnr)];
                end
                
                if isfield(results, 'dpcm') && isfield(results.dpcm, 'metrics')
                    m = results.dpcm.metrics;
                    metricsText = [metricsText, ...
                        sprintf('DPCM (α=%.3f):\n', m.predictorAlpha), ...
                        sprintf('  Bitrate: %d kbps\n', m.bitrate/1000), ...
                        sprintf('  SQNR: %.2f dB\n', m.sqnr), ...
                        sprintf('  Improvement: +%.2f dB\n\n', m.sqnr_improvement)];
                end
                
                if isfield(results, 'delta') && isfield(results.delta, 'metrics')
                    m = results.delta.metrics;
                    metricsText = [metricsText, ...
                        sprintf('Delta (Δ=%.4f):\n', m.step_size), ...
                        sprintf('  Bitrate: %d kbps\n', m.bitrate/1000), ...
                        sprintf('  SQNR: %.2f dB\n', m.sqnr), ...
                        sprintf('  Compression: %d:1\n', m.compression_ratio)];
                end
                
                text(0.05, 0.95, metricsText, 'Units', 'normalized', ...
                    'VerticalAlignment', 'top', 'FontFamily', 'monospace', ...
                    'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95]);
            end
            
        catch ME
            warning(['Error updating plots: ', ME.message]);
        end
    end
    
    function exportResults(hObject, ~)
        results = getappdata(fig, 'results');
        signal = getappdata(fig, 'signal');
        
        if isempty(results)
            msgbox('No results to export. Encode a signal first.');
            return;
        end
        
        % Export to file
        filename = sprintf('audio_analysis_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
        save(filename, 'results', 'signal');
        
        msgbox(['Results exported to: ', filename], 'Export Successful');
    end
    
    function showHelp(hObject, ~)
        helpText = ...
           'AUDIO MODULATION & QUANTIZATION ANALYSIS\n\n'...
            'Features:\n'...
            '• Load WAV files or generate test signals\n'...
            '• Compare PCM, DPCM, and Delta Modulation\n'...
            '• Adjust bit depth and quantization type\n'...
            '• Real-time visualization and analysis\n'...
            '• Export results to MAT file\n\n'...
            'Parameters:\n'...
            '• Bit Depth: 1-16 bits per sample\n'...
            '• Quantization: Uniform, A-law, µ-law\n'...
            '• DPCM Predictor α: 0-1 (0.95 optimal)\n'...
            '• Delta Step Size: 0.01-0.5\n\n'...
            'Tips:\n'...
            '• Higher bit depth = better quality\n'...
            '• DPCM better for correlated signals\n'...
            '• Delta mod uses extreme compression\n'...
            '• A-law/µ-law better for speech\n';
        
        helpfig = figure('Name', 'Help', 'NumberTitle', 'off', ...
            'Position', [400 300 500 400]);
        uicontrol('Style', 'text', 'Parent', helpfig, ...
            'String', helpText, 'Units', 'normalized', ...
            'Position', [0.05 0.05 0.9 0.9], ...
            'FontFamily', 'monospace', 'FontSize', 9, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    end
    
    function closeGUI(hObject, ~)
        delete(fig);
    end
end

%==========================================================================
% END OF GUI
%==========================================================================
