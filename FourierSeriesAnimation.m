classdef FourierSeriesAnimation < BaseAnimation
    %FOURIERSERIESANIMATION 傅里叶级数动画演示
    %   展示标准方波的傅里叶级数分解过程，通过4个子图呈现：
    %     1. 复平面上旋转向量的叠加
    %     2. 各谐波分量的波形
    %     3. 实部的谐波叠加（含轨迹显示）
    %     4. 最终合成结果与理想方波的对比

    properties
        % ---- 数据存储 ----
        t
        frequencies
        amplitudes
        thetaValues

        % ---- 轨迹数据 ----
        trajectoryDataX
        trajectoryDataY
        totalTrajectoryDataX
        totalTrajectoryDataY
        partialSumDataX
        partialSumDataY
        approxWaveDataX
        approxWaveDataY
        realTrajectoryDataX
        realTrajectoryDataY
        totalRealTrajectoryDataX
        totalRealTrajectoryDataY

        % ---- 显示配置 ----
        startFromNegativePiHalf  (1,1) logical = true
        periodsInPi              (1,1) double  = 2
    end

    methods
        function obj = FourierSeriesAnimation()
            %FOURIERSERIESANIMATION 构造函数
            obj@BaseAnimation();
            obj.createGUI();
            obj.initializeAnimationData();
            obj.initGraphics();
        end
    end

    methods (Access = protected)
        % ========== 实现抽象方法 ==========

        function createGUI(obj)
            %CREATEGUI 创建图形用户界面
            obj.fig = figure('Name', '傅里叶级数动画演示', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [100, 100, 1200, 800], ...
                'Color', [0.95, 0.95, 0.95], ...
                'Resize', 'on', ...
                'CloseRequestFcn', @(~,~) obj.closeWindow());

            obj.mainPanel = uipanel('Parent', obj.fig, ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);

            obj.controlPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.01, 0.01, 0.98, 0.12], ...
                'Title', '动画控制', ...
                'FontSize', 10, ...
                'BackgroundColor', [0.9, 0.95, 1]);

            displayPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.01, 0.15, 0.98, 0.84], ...
                'Title', '傅里叶级数动画演示', ...
                'FontSize', 11, ...
                'BackgroundColor', [1, 1, 1]);

            % 控制按钮
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '开始动画', ...
                'Position', [20, 10, 100, 30], 'FontSize', 10, ...
                'FontWeight', 'bold', 'BackgroundColor', [0.7, 0.9, 0.7], ...
                'Callback', @(~,~) obj.startAnimation());

            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '暂停/继续', ...
                'Position', [140, 10, 100, 30], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.95, 0.8], ...
                'Callback', @(~,~) obj.toggleAnimation());

            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '重置', ...
                'Position', [260, 10, 100, 30], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.8, 0.8], ...
                'Callback', @(~,~) obj.resetAnimation());

            % 速度滑块
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '动画速度:', ...
                'Position', [380, 20, 80, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            obj.animationObjects.speedSlider = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'slider', 'Position', [460, 20, 150, 20], ...
                'Min', 1, 'Max', 10, 'Value', 3, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.updateAnimationSpeed(get(src, 'Value')));

            % 起始点复选框
            obj.animationObjects.startCheckbox = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'checkbox', 'String', '从-π/2开始', ...
                'Position', [620, 20, 120, 20], ...
                'Value', obj.startFromNegativePiHalf, 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.toggleStartPoint(get(src, 'Value')));

            % 运行周期数控制
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '运行周期数(π):', ...
                'Position', [750, 25, 100, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            obj.animationObjects.periodsEdit = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'edit', 'String', num2str(obj.periodsInPi), ...
                'Position', [850, 25, 50, 20], 'FontSize', 9, ...
                'BackgroundColor', [1, 1, 1], ...
                'Callback', @(src,~) obj.updatePeriods(str2double(get(src, 'String'))));

            % 说明
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', ...
                'String', '演示内容：标准方波的傅里叶级数分解', ...
                'Position', [750, 20, 400, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            % 存储 displayPanel 引用，供 initGraphics 使用
            obj.animationObjects.displayPanel = displayPanel;
        end

        function initializeAnimationData(obj)
            %INITIALIZEANIMATIONDATA 初始化/重置所有动画数据
            if obj.startFromNegativePiHalf
                startAngle = -pi/2;
                endAngle   = -pi/2 + obj.periodsInPi * pi;
            else
                startAngle = 0;
                endAngle   = obj.periodsInPi * pi;
            end
            obj.t = linspace(startAngle, endAngle, 1000);
            obj.thetaValues = linspace(startAngle, endAngle, obj.totalFrames);

            obj.frequencies = 1:2:9;
            obj.amplitudes = 4 ./ (pi * obj.frequencies);

            nHarmonics = length(obj.frequencies);
            obj.trajectoryDataX = cell(nHarmonics, 1);
            obj.trajectoryDataY = cell(nHarmonics, 1);
            obj.totalTrajectoryDataX = [];
            obj.totalTrajectoryDataY = [];
            obj.realTrajectoryDataX = cell(nHarmonics, 1);
            obj.realTrajectoryDataY = cell(nHarmonics, 1);
            obj.totalRealTrajectoryDataX = [];
            obj.totalRealTrajectoryDataY = [];
            obj.partialSumDataX = cell(nHarmonics, 1);
            obj.partialSumDataY = cell(nHarmonics, 1);
            obj.approxWaveDataX = [];
            obj.approxWaveDataY = [];
        end

        function initGraphics(obj)
            %INITGRAPHICS 初始化所有4个子图的图形元素
            dp = obj.animationObjects.displayPanel;
            delete(findobj(dp.Children, 'Type', 'axes'));

            colors = lines(length(obj.frequencies));

            % ---- 子图1：复平面旋转向量叠加 ----
            ax1 = subplot(2, 2, 1, 'Parent', dp);
            set(ax1, 'Position', [0.07, 0.55, 0.4, 0.4]);
            % 此处通过子函数绘制，避免 initGraphics 过长
            obj.initSubplot1(ax1, colors);

            % ---- 子图2：各谐波分量波形 ----
            ax2 = subplot(2, 2, 2, 'Parent', dp);
            set(ax2, 'Position', [0.55, 0.55, 0.4, 0.4]);
            obj.initSubplot2(ax2, colors);

            % ---- 子图3：实部谐波叠加 ----
            ax3 = subplot(2, 2, 3, 'Parent', dp);
            set(ax3, 'Position', [0.07, 0.07, 0.4, 0.4]);
            obj.initSubplot3(ax3, colors);

            % ---- 子图4：合成结果 ----
            ax4 = subplot(2, 2, 4, 'Parent', dp);
            set(ax4, 'Position', [0.55, 0.07, 0.4, 0.4]);
            obj.initSubplot4(ax4);

            % 存储坐标轴引用
            obj.animationObjects.ax1 = ax1;
            obj.animationObjects.ax2 = ax2;
            obj.animationObjects.ax3 = ax3;
            obj.animationObjects.ax4 = ax4;
        end

        function updateAnimationFrame(obj)
            %UPDATEANIMATIONFRAME 更新一帧动画（由基类 updateAnimation 调用）
            if obj.currentFrame > length(obj.thetaValues)
                obj.stopAnimation();
                return;
            end
            currentTheta = obj.thetaValues(obj.currentFrame);

            % 更新子图1：复平面旋转向量
            obj.updateComplexPlane(currentTheta);

            % 更新子图2：谐波波形（根据当前时间裁剪）
            [~, timeIdx] = min(abs(obj.t - currentTheta));
            framesToShow = min(timeIdx, length(obj.t));

            obj.updateWaveformSubplot(framesToShow);
            obj.updateRealPartSubplot(currentTheta);
            obj.updateSynthesisSubplot(currentTheta, framesToShow);
        end

        function onAnimationStarted(obj)
            obj.updateButtonText('开始动画', '动画中...', 'off');
        end

        function onAnimationStopped(obj)
            obj.updateButtonText('动画中...', '开始动画', 'on');
        end
    end

    methods (Access = private)
        % ========== 子图初始化 ==========

        function initSubplot1(obj, ax, colors)
            %INITSUBPLOT1 初始化子图1：复平面旋转向量
            axes(ax); cla; hold on;
            plot([-2.5, 2.5], [0, 0], 'k-', 'LineWidth', 1);
            plot([0, 0], [-2.5, 2.5], 'k-', 'LineWidth', 1);

            nH = length(obj.frequencies);
            obj.animationObjects.vectors = cell(nH, 1);
            obj.animationObjects.vectorTips = cell(nH, 1);
            obj.animationObjects.trajectories = cell(nH, 1);

            for i = 1:nH
                obj.animationObjects.vectors{i} = plot([0, 0], [0, 0], ...
                    'Color', colors(i,:), 'LineWidth', 2);
                obj.animationObjects.vectorTips{i} = plot(0, 0, 'o', ...
                    'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), ...
                    'MarkerEdgeColor', colors(i,:));
                obj.animationObjects.trajectories{i} = plot(NaN, NaN, ...
                    'Color', colors(i,:), 'LineWidth', 0.5, 'LineStyle', '-');
            end

            obj.animationObjects.totalVector = plot([0, 0], [0, 0], ...
                'k-', 'LineWidth', 3);
            obj.animationObjects.totalTip = plot(0, 0, 'ko', ...
                'MarkerSize', 12, 'MarkerFaceColor', 'k');
            obj.animationObjects.totalTrajectory = plot(NaN, NaN, ...
                'k-', 'LineWidth', 1.5);

            axis equal; xlim([-2.5, 2.5]); ylim([-2.5, 2.5]);
            title('复平面：旋转向量叠加', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('实轴'); ylabel('虚轴'); grid on;

            % 图例
            legHandles = [obj.animationObjects.vectors{:}, ...
                obj.animationObjects.totalVector, ...
                obj.animationObjects.totalTrajectory];
            legLabels = [arrayfun(@(f) sprintf('%d次谐波', f), ...
                obj.frequencies, 'UniformOutput', false), ...
                {'合成向量', '合成轨迹'}];
            legend(legHandles, legLabels, 'Location', 'northeast', 'FontSize', 7);
            hold off;
        end

        function initSubplot2(obj, ax, colors)
            %INITSUBPLOT2 初始化子图2：各谐波分量波形
            axes(ax); cla; hold on;

            nH = length(obj.frequencies);
            obj.animationObjects.waveforms = cell(nH, 1);
            for i = 1:nH
                obj.animationObjects.waveforms{i} = plot(NaN, NaN, ...
                    'Color', colors(i,:), 'LineWidth', 1.5);
            end

            title('各谐波分量波形', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('时间 (弧度)'); ylabel('振幅'); grid on;

            xlim([obj.t(1), obj.t(end)]); ylim([-1.5, 1.5]);

            legLabels = arrayfun(@(f) sprintf('%d次谐波', f), ...
                obj.frequencies, 'UniformOutput', false);
            legend([obj.animationObjects.waveforms{:}], ...
                legLabels, 'Location', 'best', 'FontSize', 7);
            hold off;
        end

        function initSubplot3(obj, ax, colors)
            %INITSUBPLOT3 初始化子图3：实部谐波叠加
            axes(ax); cla; hold on;

            xRange = [obj.t(1), obj.t(end)];
            plot(xRange, [0, 0], 'k-', 'LineWidth', 0.5);
            obj.animationObjects.verticalLine = plot([0, 0], [-2, 2], 'k:', 'LineWidth', 1);

            nH = length(obj.frequencies);
            obj.animationObjects.realTrajectories = cell(nH, 1);
            obj.animationObjects.realVectors = cell(nH, 1);
            obj.animationObjects.realTips = cell(nH, 1);

            for i = 1:nH
                obj.animationObjects.realTrajectories{i} = plot(NaN, NaN, ...
                    'Color', [colors(i,:), 0.3], 'LineWidth', 0.8, 'LineStyle', ':');
                obj.animationObjects.realVectors{i} = plot([0, 0], [0, 0], ...
                    'Color', colors(i,:), 'LineWidth', 1.5);
                obj.animationObjects.realTips{i} = plot(0, 0, 'o', ...
                    'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), ...
                    'MarkerEdgeColor', colors(i,:));
            end

            obj.animationObjects.totalRealTrajectory = plot(NaN, NaN, ...
                'r-', 'LineWidth', 2);
            obj.animationObjects.totalRealVector = plot([0, 0], [0, 0], ...
                'r-', 'LineWidth', 2.5);
            obj.animationObjects.totalRealTip = plot(0, 0, 'ro', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'r');
            obj.animationObjects.timeMarker = plot(0, 0, 'gv', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'g');

            title('实部的谐波叠加示意（含轨迹显示）', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('时间 (弧度)'); ylabel('实轴投影值'); grid on;

            xlim([obj.t(1), obj.t(end)]); ylim([-2.5, 2.5]);

            % 简化图例
            legend([obj.animationObjects.totalRealTrajectory, ...
                obj.animationObjects.totalRealVector, ...
                obj.animationObjects.timeMarker], ...
                {'总实部轨迹', '总实部向量', '当前时间点'}, ...
                'Location', 'best', 'FontSize', 8);
            hold off;
        end

        function initSubplot4(obj, ax)
            %INITSUBPLOT4 初始化子图4：合成结果
            axes(ax); cla; hold on;

            squareWave = sign(sin(obj.t));

            obj.animationObjects.refWave = plot(obj.t, squareWave, ...
                'r--', 'LineWidth', 1.5);
            obj.animationObjects.approxWave = plot(NaN, NaN, ...
                'b-', 'LineWidth', 2);
            obj.animationObjects.approxPoint = plot(NaN, NaN, 'go', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'g');

            title('傅里叶级数逼近矩形波', 'FontSize', 11, 'FontWeight', 'bold');
            xlabel('时间 (弧度)'); ylabel('振幅'); grid on;

            xlim([obj.t(1), obj.t(end)]); ylim([-1.5, 1.5]);

            legend([obj.animationObjects.refWave, ...
                obj.animationObjects.approxWave, ...
                obj.animationObjects.approxPoint], ...
                {'理想矩形波', '傅里叶级数近似', '当前位置'}, ...
                'Location', 'best', 'FontSize', 8);
            hold off;
        end

        % ========== 帧更新子函数 ==========

        function updateComplexPlane(obj, currentTheta)
            %UPDATECOMPLEXPLANE 更新子图1的旋转向量
            totalX = 0; totalY = 0;
            for i = 1:length(obj.frequencies)
                angle = obj.frequencies(i) * currentTheta;
                x = obj.amplitudes(i) * cos(angle);
                y = obj.amplitudes(i) * sin(angle);

                hVec = obj.safeGetHandle('vectors', i);
                hTip = obj.safeGetHandle('vectorTips', i);
                if ~isempty(hVec)
                    set(hVec, 'XData', [totalX, totalX + x], ...
                              'YData', [totalY, totalY + y]);
                end
                obj.safeSet(hTip, 'XData', totalX + x, 'YData', totalY + y);

                obj.trajectoryDataX{i}(end+1) = totalX + x;
                obj.trajectoryDataY{i}(end+1) = totalY + y;
                hTraj = obj.safeGetHandle('trajectories', i);
                obj.safeSet(hTraj, ...
                    'XData', obj.trajectoryDataX{i}, ...
                    'YData', obj.trajectoryDataY{i});

                totalX = totalX + x;
                totalY = totalY + y;
            end

            obj.safeSet(obj.safeGetHandle('totalVector', 0), ...
                'XData', [0, totalX], 'YData', [0, totalY]);
            obj.safeSet(obj.safeGetHandle('totalTip', 0), ...
                'XData', totalX, 'YData', totalY);

            obj.totalTrajectoryDataX(end+1) = totalX;
            obj.totalTrajectoryDataY(end+1) = totalY;
            obj.safeSet(obj.safeGetHandle('totalTrajectory', 0), ...
                'XData', obj.totalTrajectoryDataX, ...
                'YData', obj.totalTrajectoryDataY);
        end

        function updateWaveformSubplot(obj, framesToShow)
            %UPDATEWAVEFORMSUBPLOT 更新子图2的波形
            if framesToShow <= 0, return; end
            waveX = obj.t(1:framesToShow);
            for i = 1:length(obj.frequencies)
                waveY = (4/(pi*obj.frequencies(i))) * ...
                    sin(obj.frequencies(i) * waveX);
                h = obj.safeGetHandle('waveforms', i);
                obj.safeSet(h, 'XData', waveX, 'YData', waveY);
            end
        end

        function updateRealPartSubplot(obj, currentTheta)
            %UPDATEREALPARTSUBPLOT 更新子图3的实部投影
            currentX = currentTheta;
            obj.safeSet(obj.safeGetHandle('verticalLine', 0), ...
                'XData', [currentX, currentX], 'YData', [-2, 2]);

            realParts = zeros(length(obj.frequencies), 1);
            totalReal = 0;

            for i = 1:length(obj.frequencies)
                angle = obj.frequencies(i) * currentTheta;
                realPart = obj.amplitudes(i) * cos(angle);
                realParts(i) = realPart;
                totalReal = totalReal + realPart;

                obj.realTrajectoryDataX{i}(end+1) = currentX;
                obj.realTrajectoryDataY{i}(end+1) = realPart;

                hTraj = obj.safeGetHandle('realTrajectories', i);
                obj.safeSet(hTraj, ...
                    'XData', obj.realTrajectoryDataX{i}, ...
                    'YData', obj.realTrajectoryDataY{i});
            end

            obj.totalRealTrajectoryDataX(end+1) = currentX;
            obj.totalRealTrajectoryDataY(end+1) = totalReal;
            obj.safeSet(obj.safeGetHandle('totalRealTrajectory', 0), ...
                'XData', obj.totalRealTrajectoryDataX, ...
                'YData', obj.totalRealTrajectoryDataY);

            cumulativeReal = 0;
            for i = 1:length(obj.frequencies)
                hVec = obj.safeGetHandle('realVectors', i);
                hTip = obj.safeGetHandle('realTips', i);
                obj.safeSet(hVec, ...
                    'XData', [currentX, currentX], ...
                    'YData', [cumulativeReal, cumulativeReal + realParts(i)]);
                obj.safeSet(hTip, ...
                    'XData', currentX, 'YData', cumulativeReal + realParts(i));
                cumulativeReal = cumulativeReal + realParts(i);
            end

            obj.safeSet(obj.safeGetHandle('totalRealVector', 0), ...
                'XData', [currentX, currentX], 'YData', [0, totalReal]);
            obj.safeSet(obj.safeGetHandle('totalRealTip', 0), ...
                'XData', currentX, 'YData', totalReal);
            obj.safeSet(obj.safeGetHandle('timeMarker', 0), ...
                'XData', currentX, 'YData', 0);
        end

        function updateSynthesisSubplot(obj, currentTheta, framesToShow)
            %UPDATESYNTHESISSUBPLOT 更新子图4的合成波形
            if framesToShow <= 0, return; end
            approxSignal = zeros(1, framesToShow);
            for i = 1:length(obj.frequencies)
                approxSignal = approxSignal + (4/(pi*obj.frequencies(i))) * ...
                    sin(obj.frequencies(i) * obj.t(1:framesToShow));
            end

            obj.approxWaveDataX = obj.t(1:framesToShow);
            obj.approxWaveDataY = approxSignal;

            obj.safeSet(obj.safeGetHandle('approxWave', 0), ...
                'XData', obj.approxWaveDataX, 'YData', obj.approxWaveDataY);
            obj.safeSet(obj.safeGetHandle('approxPoint', 0), ...
                'XData', currentTheta, 'YData', approxSignal(end));
        end
    end

    methods
        % ========== 公共回调 ==========

        function toggleStartPoint(obj, value)
            %TOGGLESTARTPOINT 切换动画起始点（-π/2 或 0）
            obj.startFromNegativePiHalf = value;
            obj.resetAnimation();
        end

        function updatePeriods(obj, value)
            %UPDATEPERIODS 更新运行周期数
            if ~isempty(value) && isnumeric(value) && value > 0
                obj.periodsInPi = value;
                obj.resetAnimation();
            else
                set(obj.animationObjects.periodsEdit, 'String', num2str(obj.periodsInPi));
                errordlg('请输入有效的正数周期值', '输入错误');
            end
        end

    end
end
