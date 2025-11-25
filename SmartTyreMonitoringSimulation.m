function SmartTyreMonitoringSimulation
    
    %%  1. CONFIGURATION
    Fs = 200000;           
    WindowSize = 0.05;     
    t = 0:1/Fs:WindowSize; 
    
    F_start = 25000; F_end = 95000;
    
    HistoryLen = 200;
    SpecBins = 100;
    SpectrogramBuffer = -120 * ones(SpecBins, HistoryLen);
    MaxSensors = 20;
    HeatmapBuffer = zeros(MaxSensors, HistoryLen);
    
    EventState = 'NONE';
    EventTimer = 0;
    CurrentView = 1; 
    
    try; [b_filt, a_filt] = butter(2, [20000 99000]/(Fs/2), 'bandpass');
    catch; b_filt = [0.6, 0, -0.6]; a_filt = [1, -0.5, 0.2]; end
    
    DSP_Modes = {'AUTO', 'MANUAL_ON', 'OFF'};
    CurrentDSPMode = 3; 

    %%  2. INTERFACE
    fig = uifigure('Name', 'F1 Tyre Sim : ORIGINAL VISUALS', ...
        'Position', [50 50 1200 950], 'Color', [0.12 0.12 0.12]);
    
    uilabel(fig, 'Position', [20 910 800 30], ...
        'Text', 'TYRE TELEMETRY: RESTORED VISUALS', ...
        'FontColor', [0 1 1], 'FontSize', 18, 'FontWeight', 'bold');

    % --- Graphs ---
    
    % TOP
    axTime = uiaxes(fig, 'Position', [20 680 750 200], ...
        'Color', [0 0 0], 'XColor', 'w', 'YColor', 'w');
    title(axTime, 'SIGNAL CHAIN', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    ylim(axTime, [-15 15]); grid(axTime, 'on');
    
    % MIDDLE (Hybrid)
    axHybrid = uiaxes(fig, 'Position', [30 380 740 260], ...
        'Color', [0 0 0], 'XColor', 'w', 'YColor', 'w');
    
    btnSwitchView = uibutton(fig, 'Position', [600 645 170 25], ...
        'Text', 'SWITCH TO HEATMAP', 'BackgroundColor', [0.2 0.2 0.2], 'FontColor', 'w', ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,e) toggleView(btn));
    
    % BOTTOM (Profile)
    axProfile = uiaxes(fig, 'Position', [30 60 740 280], ...
        'Color', [0 0 0], 'XColor', 'w', 'YColor', 'w');
    title(axProfile, 'LOAD DISTRIBUTION', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
    ylim(axProfile, [0 30]); grid(axProfile, 'on'); % Вернул лимит 30, как в CleanUI
    
    % --- Settings ---
    pnlPhys = uipanel(fig, 'Position', [790 600 380 340], ...
        'Title', '1. SENSOR CONFIG', ...
        'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    
    uilabel(pnlPhys, 'Position', [20 280 300 20], 'Text', 'SENSOR COUNT', 'FontColor', [0 1 0], 'FontWeight', 'bold');
    lblSensCount = uilabel(pnlPhys, 'Position', [320 280 50 20], 'Text', '5', 'FontColor', [0 1 0], 'FontWeight', 'bold');
    sldSensors = uislider(pnlPhys, 'Position', [20 255 340 3], 'Limits', [3 20], 'Value', 5, ...
        'MajorTicks', [3 5 10 15 20], 'FontColor', 'w', ...
        'ValueChangedFcn', @(sld,event) updateSensorLabel(sld, lblSensCount));
    
    uilabel(pnlPhys, 'Position', [20 210 300 20], 'Text', 'RPM', 'FontColor', 'w', 'FontWeight', 'bold');
    sldRPM = uislider(pnlPhys, 'Position', [20 185 340 3], 'Limits', [500 4000], 'Value', 1500, 'FontColor', 'w');
    
    uilabel(pnlPhys, 'Position', [20 140 300 20], 'Text', 'CAMBER', 'FontColor', 'c', 'FontWeight', 'bold');
    sldCamber = uislider(pnlPhys, 'Position', [20 115 340 3], 'Limits', [-2 2], 'Value', -0.5, 'FontColor', 'c'); 
    
    uilabel(pnlPhys, 'Position', [20 70 300 20], 'Text', 'NOISE LEVEL', 'FontColor', 'y', 'FontWeight', 'bold');
    sldNoise = uislider(pnlPhys, 'Position', [20 45 340 3], 'Limits', [0 5], 'Value', 1.0, 'FontColor', 'y');

    pnlDSP = uipanel(fig, 'Position', [790 350 380 210], ...
        'Title', '2. DSP UNIT', 'BackgroundColor', [0 0.25 0.3], 'ForegroundColor', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    
    btnDSPMode = uibutton(pnlDSP, 'Position', [20 110 340 50], ...
        'Text', 'MODE: AUTO-ADAPTIVE', 'BackgroundColor', [0 0.6 0.9], 'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,event) cycleDSPMode(btn));
        
    uilabel(pnlDSP, 'Position', [20 70 300 20], 'Text', 'AMPLIFIER GAIN', 'FontColor', 'g', 'FontWeight', 'bold');
    sldGain = uislider(pnlDSP, 'Position', [20 45 340 3], 'Limits', [1 10], 'Value', 3, 'FontColor', 'g');
    
    pnlEvents = uipanel(fig, 'Position', [790 20 380 310], ...
        'Title', '3. SCENARIOS', 'BackgroundColor', [0.3 0 0], 'ForegroundColor', 'w', 'FontSize', 14, 'FontWeight', 'bold');
    
    uibutton(pnlEvents, 'Position', [20 220 340 50], 'Text', 'KERB HIT', 'BackgroundColor', [1 0.4 0], 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) triggerEvent('KERB'));
    uibutton(pnlEvents, 'Position', [20 150 340 50], 'Text', 'DEBRIS IMPACT', 'BackgroundColor', [0.7 0.7 0.7], 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) triggerEvent('DEBRIS'));
    uibutton(pnlEvents, 'Position', [20 80 340 50], 'Text', 'LOCK-UP', 'BackgroundColor', [0.7 0 0], 'FontColor', 'w', 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) triggerEvent('LOCK'));
    uibutton(pnlEvents, 'Position', [20 20 340 40], 'Text', 'STOP', 'BackgroundColor', 'k', 'FontColor', 'w', 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn,event) stopApp());

    %%  3. INIT
    running = true;
    
    hLineInput = line(axTime, t*1000, zeros(size(t)), 'Color', [1 0.2 0.2 0.4], 'LineWidth', 1); 
    hLineOutput = line(axTime, t*1000, zeros(size(t)), 'Color', [0 1 0], 'LineWidth', 1.5);
    
    hHybridImg = imagesc(axHybrid, SpectrogramBuffer);
    colormap(axHybrid, 'jet'); 
    
    hStem = stem(axProfile, 1:5, zeros(1,5), 'filled', 'LineStyle', '-', 'LineWidth', 4, 'MarkerSize', 10, 'Color', 'c');
    
    pulse_timer = 0; 
    prev_n_sens = 0; 
    updateViewAxis();
    
    %% 4. LOOP
    while running && isvalid(fig)
        rpm = sldRPM.Value; camber = sldCamber.Value; noise_lvl = sldNoise.Value; gain_val = sldGain.Value; n_sens = round(sldSensors.Value);
        
        if n_sens ~= prev_n_sens
            CurrentFreqs = linspace(F_start, F_end, n_sens);
            axProfile.XLim = [0.5, n_sens + 0.5];
            axProfile.XTick = [1, n_sens]; axProfile.XTickLabel = {'INNER EDGE', 'OUTER EDGE'};
            if CurrentView == 2; set(hHybridImg, 'YData', [1 n_sens]); ylim(axHybrid, [0.5 n_sens+0.5]); end
            prev_n_sens = n_sens;
        end
        
        % --- PHYSICS ---
        raw_physics = zeros(size(t));
        samples_per_rev = (60/rpm) * Fs;
        pulse_timer = pulse_timer + length(t);
        
        if pulse_timer > samples_per_rev
            pulse_timer = 0;
            x_range = linspace(-2, 2, n_sens);
            TrueLoads = exp(-((x_range - camber).^2) / (2*1.2^2)); 
            carrier = zeros(size(t)); 
            for k=1:n_sens
                carrier = carrier + TrueLoads(k) * sin(2*pi*CurrentFreqs(k)*t); 
            end
            raw_physics = raw_physics + (hamming(length(t))' .* carrier);
        end
        
        if EventTimer > 0
            EventTimer = EventTimer - 1;
            switch EventState
                case 'KERB'
                    idx_kerb = round(n_sens * 0.8); kerb_sig = zeros(size(t));
                    for k = idx_kerb:n_sens; kerb_sig = kerb_sig + 5*sin(2*pi*CurrentFreqs(k)*t); end
                    raw_physics = raw_physics + kerb_sig .* (rand(size(t))>0.2); 
                case 'DEBRIS'
                    raw_physics = raw_physics + 25.0 * randn(size(t)) .* exp(-40*t);
                case 'LOCK'
                    if EventTimer > 10; raw_physics = raw_physics * 0.05; else; raw_physics = raw_physics + 5.0 * randn(size(t)) .* exp(-20*t); end
            end
        end
        
        input_signal = raw_physics + noise_lvl * randn(size(t));
        
        % --- DSP ---
        modeStr = DSP_Modes{CurrentDSPMode};
        FilterActive = false;
        switch modeStr
            case 'AUTO'; if noise_lvl > 1.2 || EventTimer > 0; FilterActive = true; end
            case 'MANUAL_ON'; FilterActive = true;
        end
        
        if FilterActive; final_signal = filter(b_filt, a_filt, input_signal);
        else; final_signal = input_signal; end
        final_signal = final_signal * gain_val;
        
        % --- VISUAL CALCULATIONS (RESTORED MATH) ---
        L = length(final_signal); Y = abs(fft(final_signal)); 
        
        P1 = Y(1:floor(L/2)+1); 
        
        SpectrogramBuffer(:,1:end-1) = SpectrogramBuffer(:,2:end);
       
        SpectrogramBuffer(:,end) = 20*log10(abs(resample(P1,SpecBins,length(P1)))+1e-6);
        
        Decoded = zeros(1, n_sens); 
        road_jitter = 0.9 + 0.2*rand(1, n_sens);
        
        for k=1:n_sens
            freq_idx = round(CurrentFreqs(k)/(Fs/2)*length(P1));
            idx_range = max(1, freq_idx-5) : min(length(P1), freq_idx+5); % Диапазон 5, как было
            Decoded(k) = (mean(P1(idx_range))/(gain_val*20)) * road_jitter(k);
        end
        
        HeatmapBuffer(1:n_sens, 1:end-1) = HeatmapBuffer(1:n_sens, 2:end);
        HeatmapBuffer(1:n_sens, end) = Decoded';
        
        hLineInput.YData = input_signal; hLineOutput.YData = final_signal;
        set(hStem, 'XData', 1:n_sens, 'YData', Decoded);
        
        if CurrentView == 1
            set(hHybridImg, 'CData', SpectrogramBuffer); set(hHybridImg, 'YData', [1 SpecBins]); 
        else
            set(hHybridImg, 'CData', HeatmapBuffer(1:n_sens, :)); set(hHybridImg, 'YData', [1 n_sens]);
        end

        drawnow limitrate;
    end
    
    %% FUNCTIONS
    function toggleView(btn)
        if CurrentView == 1; CurrentView = 2; btn.Text = 'SWITCH TO SPECTROGRAM'; btn.BackgroundColor = [0 0.4 0.4];
        else; CurrentView = 1; btn.Text = 'SWITCH TO HEATMAP'; btn.BackgroundColor = [0.2 0.2 0.2]; end
        updateViewAxis();
    end

    function updateViewAxis()
        if CurrentView == 1
            title(axHybrid, 'VIEW: SPECTROGRAM (Frequency)', 'Color', 'c', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(axHybrid, 'Freq (20k - 100k)');
            
            
            caxis(axHybrid, [-40 60]); 
            
            ylim(axHybrid, [0.5 SpecBins+0.5]); axHybrid.YTickLabelMode = 'auto';
            colormap(axHybrid, 'jet'); 
        else
            title(axHybrid, 'VIEW: HEATMAP (Tire Load)', 'Color', 'g', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel(axHybrid, 'Sensor Pos');
            caxis(axHybrid, [0 20]); % Масштаб для Heatmap подстроен под амплитуду
            ylim(axHybrid, [0.5 sldSensors.Value+0.5]); axHybrid.YTick = []; 
            colormap(axHybrid, 'jet'); 
        end
    end

    function updateSensorLabel(sld, lbl); lbl.Text = num2str(round(sld.Value)); end
    function cycleDSPMode(btn)
        CurrentDSPMode = CurrentDSPMode + 1; if CurrentDSPMode > 3; CurrentDSPMode = 1; end
        modes = {'AUTO-ADAPTIVE', 'MANUAL', 'OFF'}; btn.Text = ['MODE: ' modes{CurrentDSPMode}];
    end
    function triggerEvent(type); EventState = type; EventTimer = 25; end
    function stopApp(); running = false; delete(fig); end
end