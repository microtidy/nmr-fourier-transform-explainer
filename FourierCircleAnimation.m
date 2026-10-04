classdef FourierCircleAnimation < BaseAnimation
    %FOURIERCIRCLEANIMATION 傅里叶圆动画演示
    %   展示傅里叶级数分解中旋转向量叠加生成波形的过程。
    %   包含三个区域：左侧旋转向量叠加、右侧 y 轴投影（波形）、下方 x 轴投影。

    properties
        % ---- 信号数据 ----
        t
        frequencies
        amplitudes
        thetaValues

        % ---- 轨迹数据 ----
        trajectoryDataX
        trajectoryDataY
        totalTrajectoryDataX
        totalTrajectoryDataY

        % ---- 右侧方波数据 ----
        waveDataX
        waveDataY
        waveHistoryX
        waveHistoryY

        % ---- 下方投影数据 ----
        projectionDataX
        projectionDataY
        projectionHistoryX
        projectionHistoryY
        projectionIdealDataX
        projectionIdealDataY

        % ---- 显示配置 ----
        startFromNegativePiHalf  (1,1) logical = true
        reverseRotation          (1,1) logical = false
        periodsInPi              (1,1) double  = 2
        waveDrawingStartX        (1,1) double  = 4.5
        waveDrawingEndX          (1,1) double  = 14.5
        waveDrawingSpeed         (1,1) double  = 0.05
        projectionDrawingStartY  (1,1) double  = -3.0
        projectionDrawingEndY    (1,1) double  = -9.0
    end

    methods
        function obj = FourierCircleAnimation()
            %FOURIERCIRCLEANIMATION 构造函数
            obj@BaseAnimation();
            obj.createGUI();
            obj.initializeAnimationData();
            obj.initGraphics();
            obj.onAnimationStopped();
        end
    end

    methods (Access = protected)
        % ========== 实现抽象方法 ==========

        function createGUI(obj)
            %CREATEGUI 创建图形用户界面
            obj.fig = figure('Name', '傅里叶圆动画演示 - 旋转向量叠加与波形生成', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [100, 100, 1400, 800], ...
                'Color', [0.95, 0.95, 0.95], ...
                'Resize', 'on', ...
                'CloseRequestFcn', @(~,~) obj.closeWindow());

            obj.mainPanel = uipanel('Parent', obj.fig, ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);

            obj.controlPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.01, 0.01, 0.98, 0.15], ...
                'Title', '动画控制', ...
                'FontSize', 10, ...
                'BackgroundColor', [0.9, 0.95, 1]);

            % 控制按钮
            obj.animationObjects.startButton = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '开始动画', ...
                'Position', [20, 15, 100, 30], 'FontSize', 10, ...
                'FontWeight', 'bold', 'BackgroundColor', [0.7, 0.9, 0.7], ...
                'Callback', @(~,~) obj.startAnimation());

            obj.animationObjects.pauseButton = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '暂停/继续', ...
                'Position', [140, 15, 100, 30], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.95, 0.8], ...
                'Callback', @(~,~) obj.toggleAnimation());

            obj.animationObjects.resetButton = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '重置', ...
                'Position', [260, 15, 100, 30], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.8, 0.8], ...
                'Callback', @(~,~) obj.resetAnimation());

            % 速度控制
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '动画速度:', ...
                'Position', [380, 25, 80, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            obj.animationObjects.speedSlider = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'slider', 'Position', [460, 25, 150, 20], ...
                'Min', 1, 'Max', 10, 'Value', 3, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.updateAnimationSpeed(get(src, 'Value')));

            % 起始点复选框
            obj.animationObjects.startCheckbox = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'checkbox', 'String', '从-π/2开始', ...
                'Position', [620, 25, 120, 20], ...
                'Value', obj.startFromNegativePiHalf, 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.toggleStartPoint(get(src, 'Value')));

            % 反转方向复选框
            obj.animationObjects.reverseCheckbox = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'checkbox', 'String', '反转旋转方向', ...
                'Position', [620, 5, 120, 20], ...
                'Value', obj.reverseRotation, 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.toggleReverseRotation(get(src, 'Value')));

            % 周期控制
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '运行周期数(π):', ...
                'Position', [750, 25, 120, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            obj.animationObjects.periodsEdit = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'edit', 'String', num2str(obj.periodsInPi), ...
                'Position', [870, 25, 50, 20], 'FontSize', 9, ...
                'BackgroundColor', [1, 1, 1], ...
                'Callback', @(src,~) obj.updatePeriods(str2double(get(src, 'String'))));

            % 说明文本
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', ...
                'String', '演示内容：傅里叶级数分解 - 旋转向量叠加生成波形', ...
                'Position', [750, 5, 400, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'HorizontalAlignment', 'left');

            % 主坐标轴
            obj.animationObjects.axesMain = axes('Parent', obj.mainPanel, ...
                'Position', [0.05, 0.2, 0.9, 0.75], 'Box', 'on');
        end

        function initializeAnimationData(obj)
            %INITIALIZEANIMATIONDATA 初始化/重置所有动画数据
            if obj.startFromNegativePiHalf
                startAngle = -pi/2;
                endAngle = -pi/2 + obj.periodsInPi * pi;
            else
                startAngle = 0;
                endAngle = obj.periodsInPi * pi;
            end

            obj.t = linspace(startAngle, endAngle, 1000);
            if obj.reverseRotation
                obj.thetaValues = linspace(endAngle, startAngle, obj.totalFrames);
            else
                obj.thetaValues = linspace(startAngle, endAngle, obj.totalFrames);
            end

            obj.frequencies = 1:2:9;
            obj.amplitudes = 4 ./ (pi * obj.frequencies);

            nH = length(obj.frequencies);
            obj.trajectoryDataX = cell(nH, 1);
            obj.trajectoryDataY = cell(nH, 1);
            obj.totalTrajectoryDataX = [];
            obj.totalTrajectoryDataY = [];
            obj.waveDataX = [];
            obj.waveDataY = [];
            obj.waveHistoryX = [];
            obj.waveHistoryY = [];
            obj.projectionDataX = [];
            obj.projectionDataY = [];
            obj.projectionHistoryX = [];
            obj.projectionHistoryY = [];
            obj.projectionIdealDataX = [];
            obj.projectionIdealDataY = [];
        end

        function initGraphics(obj)
            %INITGRAPHICS 初始化所有图形元素
            ax = obj.animationObjects.axesMain;
            axes(ax); cla; hold on;

            axis equal;
            xlim([-3.5, 15.5]);
            ylim([-12.5, 5.5]);

            % 坐标轴
            plot([-3, 3], [0, 0], 'k-', 'LineWidth', 1.2);
            plot([0, 0], [-12, 5], 'k-', 'LineWidth', 1.2);

            % 右侧方波区域参考线
            plot([obj.waveDrawingStartX-0.2, obj.waveDrawingEndX+0.2], [0, 0], 'k-', 'LineWidth', 0.8);
            plot([obj.waveDrawingStartX, obj.waveDrawingStartX], [-3, 3], 'k--', 'LineWidth', 0.8);
            plot([obj.waveDrawingEndX, obj.waveDrawingEndX], [-3, 3], 'k--', 'LineWidth', 0.8);

            % 下方投影区域参考线
            plot([-3, 3], [obj.projectionDrawingStartY, obj.projectionDrawingStartY], 'k-', 'LineWidth', 0.8);
            plot([-3, 3], [obj.projectionDrawingEndY, obj.projectionDrawingEndY], 'k-', 'LineWidth', 0.8);
            plot([0, 0], [obj.projectionDrawingEndY, obj.projectionDrawingStartY], 'k--', 'LineWidth', 0.8);

            colors = lines(length(obj.frequencies));
            nH = length(obj.frequencies);

            % 旋转向量和轨迹
            obj.animationObjects.vectors = cell(nH, 1);
            obj.animationObjects.vectorTips = cell(nH, 1);
            obj.animationObjects.trajectories = cell(nH, 1);
            obj.animationObjects.circleTrajectories = cell(nH, 1);

            for i = 1:nH
                obj.animationObjects.vectors{i} = plot([0, 0], [0, 0], ...
                    'Color', colors(i,:), 'LineWidth', 2.2);
                obj.animationObjects.vectorTips{i} = plot(0, 0, 'o', ...
                    'MarkerSize', 9, 'MarkerFaceColor', colors(i,:), ...
                    'MarkerEdgeColor', colors(i,:), 'LineWidth', 1.5);
                obj.animationObjects.trajectories{i} = plot(NaN, NaN, ...
                    'Color', [colors(i,:), 0.15], 'LineWidth', 0.5, 'LineStyle', '-');
            end

            % 总向量
            obj.animationObjects.totalVector = plot([0, 0], [0, 0], ...
                'k-', 'LineWidth', 3.5);
            obj.animationObjects.totalTip = plot(0, 0, 'ko', ...
                'MarkerSize', 14, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
            obj.animationObjects.totalTrajectory = plot(NaN, NaN, 'k-', 'LineWidth', 2);

            % 右侧方波绘制
            obj.animationObjects.waveMarkerLine = plot([0, 0], [0, 0], ...
                'r--', 'LineWidth', 1.5, 'LineStyle', '-.');
            obj.animationObjects.waveMarkerArrow = plot(0, 0, 'r>', ...
                'MarkerSize', 12, 'MarkerFaceColor', 'r');
            obj.animationObjects.waveTrajectory = plot(NaN, NaN, 'b-', 'LineWidth', 2);
            obj.animationObjects.idealWaveTrajectory = plot(NaN, NaN, 'm--', 'LineWidth', 1.5);
            obj.animationObjects.currentWavePoint = plot(0, 0, 'go', ...
                'MarkerSize', 12, 'MarkerFaceColor', 'g');
            obj.animationObjects.currentIdealPoint = plot(0, 0, 'mo', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'm');

            % 下方投影绘制
            obj.animationObjects.projectionMarkerLine = plot([0, 0], [0, 0], ...
                'g--', 'LineWidth', 1.5, 'LineStyle', '-.');
            obj.animationObjects.projectionMarkerArrow = plot(0, 0, 'gv', ...
                'MarkerSize', 12, 'MarkerFaceColor', 'g');
            obj.animationObjects.projectionTrajectory = plot(NaN, NaN, 'c-', 'LineWidth', 2);
            obj.animationObjects.idealProjectionTrajectory = plot(NaN, NaN, 'y--', 'LineWidth', 1.5);
            obj.animationObjects.currentProjectionPoint = plot(0, 0, 'ro', ...
                'MarkerSize', 12, 'MarkerFaceColor', 'r');
            obj.animationObjects.currentIdealProjectionPoint = plot(0, 0, 'yo', ...
                'MarkerSize', 10, 'MarkerFaceColor', 'y');

            % 文字标注
            title('傅里叶圆动画：旋转向量叠加生成波形', 'FontSize', 14, 'FontWeight', 'bold');
            xlabel('实轴 (左侧：向量叠加，右侧：y轴投影)', 'FontSize', 11);
            ylabel('虚轴 / 振幅 (下方：x轴投影)', 'FontSize', 11);

            text(-2.8, 4.8, '向量叠加区域', 'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.9, 0.95, 1], 'EdgeColor', 'blue');

            regionWidth = obj.waveDrawingEndX - obj.waveDrawingStartX;
            text(obj.waveDrawingStartX + regionWidth/2 - 1.5, 4.8, 'y轴投影区域', ...
                'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.95, 0.9, 1], 'EdgeColor', 'red');

            text(-2.8, obj.projectionDrawingStartY + 0.3, 'x轴投影区域', ...
                'FontSize', 10, 'FontWeight', 'bold', ...
                'BackgroundColor', [0.95, 1, 0.9], 'EdgeColor', 'green');

            % 信息文本
            reverseText = ternary(obj.reverseRotation, '反转', '正转');
            startText = ternary(obj.startFromNegativePiHalf, '从-π/2开始', '从0开始');
            infoText = sprintf('当前设置：%s, %s, 运行%.1fπ周期', ...
                startText, reverseText, obj.periodsInPi);
            text(-2.8, -11.5, infoText, 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', [1, 1, 0.9], 'EdgeColor', 'black');

            % 图例
            legHandles = [obj.animationObjects.vectors{:}, ...
                obj.animationObjects.trajectories{1}, ...
                obj.animationObjects.totalVector, ...
                obj.animationObjects.totalTrajectory, ...
                obj.animationObjects.waveMarkerLine, ...
                obj.animationObjects.waveTrajectory, ...
                obj.animationObjects.idealWaveTrajectory, ...
                obj.animationObjects.currentWavePoint, ...
                obj.animationObjects.projectionMarkerLine, ...
                obj.animationObjects.projectionTrajectory, ...
                obj.animationObjects.idealProjectionTrajectory, ...
                obj.animationObjects.currentProjectionPoint];

            legLabels = [arrayfun(@(f) sprintf('基频×%d (r=%.2f)', f, 4/(pi*f)), ...
                obj.frequencies, 'UniformOutput', false), ...
                {'谐波轨迹', '合成向量', '合成轨迹', ...
                 'y轴投影标记线', '近似y轴投影', '理想y轴投影', 'y轴当前位置', ...
                 'x轴投影标记线', '近似x轴投影', '理想x轴投影', 'x轴当前位置'}];

            legend(legHandles, legLabels, 'Location', 'southeast', ...
                'FontSize', 8, 'NumColumns', 3);
            grid on;
            hold off;
        end

        function updateAnimationFrame(obj)
            %UPDATEANIMATIONFRAME 更新一帧动画
            if obj.currentFrame > length(obj.thetaValues)
                obj.stopAnimation();
                return;
            end
            currentTheta = obj.thetaValues(obj.currentFrame);

            % 更新旋转向量
            [totalX, totalY] = obj.updateRotationVectors(currentTheta);

            % 更新右侧方波投影
            obj.updateWaveProjection(currentTheta, totalX, totalY);

            % 更新下方 x 轴投影
            obj.updateProjectionAnimation(totalX, totalY);

            % 动态调整坐标轴范围
            if mod(obj.currentFrame, 50) == 0
                obj.adjustAxisLimits();
            end
        end

        function onAnimationStarted(obj)
            obj.updateStartButton('开始动画', '动画中...', 'off');
        end

        function onAnimationStopped(obj)
            obj.updateStartButton('动画中...', '开始动画', 'on');
        end
    end

    methods (Access = private)
        % ========== 帧更新子函数 ==========

        function [totalX, totalY] = updateRotationVectors(obj, currentTheta)
            %UPDATEROTATIONVECTORS 更新左侧旋转向量叠加
            totalX = 0; totalY = 0;
            prevX = 0; prevY = 0;

            for i = 1:length(obj.frequencies)
                angle = obj.frequencies(i) * currentTheta;
                x = obj.amplitudes(i) * cos(angle);
                y = obj.amplitudes(i) * sin(angle);

                hVec = obj.safeGetHandle('vectors', i);
                hTip = obj.safeGetHandle('vectorTips', i);
                obj.safeSet(hVec, 'XData', [prevX, prevX + x], ...
                                   'YData', [prevY, prevY + y]);
                obj.safeSet(hTip, 'XData', prevX + x, 'YData', prevY + y);

                % 更新圆形轨道
                radius = obj.amplitudes(i);
                thetaCircle = linspace(0, 2*pi, 100);
                xCircle = prevX + radius * cos(thetaCircle);
                yCircle = prevY + radius * sin(thetaCircle);

                hCircle = obj.safeGetHandle('circleTrajectories', i);
                if isempty(hCircle)
                    axes(obj.animationObjects.axesMain); hold on;
                    colors = lines(length(obj.frequencies));
                    obj.animationObjects.circleTrajectories{i} = ...
                        plot(xCircle, yCircle, 'Color', [colors(i,:), 0.5], ...
                             'LineWidth', 1.0, 'LineStyle', '--');
                    hold off;
                else
                    set(hCircle, 'XData', xCircle, 'YData', yCircle);
                end

                % 轨迹
                obj.trajectoryDataX{i}(end+1) = prevX + x;
                obj.trajectoryDataY{i}(end+1) = prevY + y;
                hTraj = obj.safeGetHandle('trajectories', i);
                obj.safeSet(hTraj, 'XData', obj.trajectoryDataX{i}, ...
                                   'YData', obj.trajectoryDataY{i});

                prevX = prevX + x;
                prevY = prevY + y;
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

        function updateWaveProjection(obj, currentTheta, totalX, totalY)
            %UPDATEWAVEPROJECTION 更新右侧 y 轴投影（打印机效果）
            approxValue = 0;
            for i = 1:length(obj.frequencies)
                approxValue = approxValue + (4/(pi*obj.frequencies(i))) * ...
                    sin(obj.frequencies(i) * currentTheta);
            end

            idealValue = sign(sin(currentTheta));
            if abs(sin(currentTheta)) < 1e-10
                idealValue = 0;
            end

            % 打印机效果：新点在左侧，旧点右移
            shiftAmount = 0.03;
            if isempty(obj.waveDataX)
                obj.waveDataX = obj.waveDrawingStartX;
                obj.waveDataY = approxValue;
                obj.waveHistoryX = obj.waveDrawingStartX;
                obj.waveHistoryY = idealValue;
            else
                obj.waveDataX = obj.waveDataX + shiftAmount;
                obj.waveHistoryX = obj.waveHistoryX + shiftAmount;
                obj.waveDataX = [obj.waveDrawingStartX, obj.waveDataX];
                obj.waveDataY = [approxValue, obj.waveDataY];
                obj.waveHistoryX = [obj.waveDrawingStartX, obj.waveHistoryX];
                obj.waveHistoryY = [idealValue, obj.waveHistoryY];

                validIdx = obj.waveDataX <= obj.waveDrawingEndX;
                obj.waveDataX = obj.waveDataX(validIdx);
                obj.waveDataY = obj.waveDataY(validIdx);
                validIdx = obj.waveHistoryX <= obj.waveDrawingEndX;
                obj.waveHistoryX = obj.waveHistoryX(validIdx);
                obj.waveHistoryY = obj.waveHistoryY(validIdx);
            end

            obj.safeSet(obj.safeGetHandle('waveTrajectory', 0), ...
                'XData', obj.waveDataX, 'YData', obj.waveDataY);
            obj.safeSet(obj.safeGetHandle('idealWaveTrajectory', 0), ...
                'XData', obj.waveHistoryX, 'YData', obj.waveHistoryY);
            obj.safeSet(obj.safeGetHandle('waveMarkerLine', 0), ...
                'XData', [totalX, obj.waveDrawingStartX], ...
                'YData', [totalY, approxValue]);
            obj.safeSet(obj.safeGetHandle('waveMarkerArrow', 0), ...
                'XData', obj.waveDrawingStartX, 'YData', approxValue);
            obj.safeSet(obj.safeGetHandle('currentWavePoint', 0), ...
                'XData', obj.waveDrawingStartX, 'YData', approxValue);
            obj.safeSet(obj.safeGetHandle('currentIdealPoint', 0), ...
                'XData', obj.waveDrawingStartX, 'YData', idealValue);
        end

        function updateProjectionAnimation(obj, totalX, totalY)
            %UPDATEPROJECTIONANIMATION 更新下方 x 轴投影
            shiftAmountY = 0.03;
            if isempty(obj.projectionDataX)
                obj.projectionDataX = 0;
                obj.projectionDataY = obj.projectionDrawingStartY;
                obj.projectionHistoryX = [totalX];
                obj.projectionHistoryY = [obj.projectionDrawingStartY];
                obj.projectionIdealDataX = [0];
                obj.projectionIdealDataY = [obj.projectionDrawingStartY];
            else
                obj.projectionDataY = obj.projectionDataY - shiftAmountY;
                obj.projectionHistoryY = obj.projectionHistoryY - shiftAmountY;
                obj.projectionIdealDataY = obj.projectionIdealDataY - shiftAmountY;

                obj.projectionDataX = [totalX, obj.projectionDataX];
                obj.projectionDataY = [obj.projectionDrawingStartY, obj.projectionDataY];
                obj.projectionHistoryX = [totalX, obj.projectionHistoryX];
                obj.projectionHistoryY = [obj.projectionDrawingStartY, obj.projectionHistoryY];
                obj.projectionIdealDataX = [0, obj.projectionIdealDataX];
                obj.projectionIdealDataY = [obj.projectionDrawingStartY, obj.projectionIdealDataY];

                validIdx = obj.projectionDataY >= obj.projectionDrawingEndY;
                obj.projectionDataX = obj.projectionDataX(validIdx);
                obj.projectionDataY = obj.projectionDataY(validIdx);
                validIdx = obj.projectionHistoryY >= obj.projectionDrawingEndY;
                obj.projectionHistoryX = obj.projectionHistoryX(validIdx);
                obj.projectionHistoryY = obj.projectionHistoryY(validIdx);
                validIdx = obj.projectionIdealDataY >= obj.projectionDrawingEndY;
                obj.projectionIdealDataX = obj.projectionIdealDataX(validIdx);
                obj.projectionIdealDataY = obj.projectionIdealDataY(validIdx);
            end

            obj.safeSet(obj.safeGetHandle('projectionTrajectory', 0), ...
                'XData', obj.projectionHistoryX, 'YData', obj.projectionHistoryY);
            obj.safeSet(obj.safeGetHandle('idealProjectionTrajectory', 0), ...
                'XData', obj.projectionIdealDataX, 'YData', obj.projectionIdealDataY);
            obj.safeSet(obj.safeGetHandle('projectionMarkerLine', 0), ...
                'XData', [totalX, totalX], ...
                'YData', [totalY, obj.projectionDrawingStartY]);
            obj.safeSet(obj.safeGetHandle('projectionMarkerArrow', 0), ...
                'XData', totalX, 'YData', obj.projectionDrawingStartY);
            obj.safeSet(obj.safeGetHandle('currentProjectionPoint', 0), ...
                'XData', totalX, 'YData', obj.projectionDrawingStartY);
            obj.safeSet(obj.safeGetHandle('currentIdealProjectionPoint', 0), ...
                'XData', 0, 'YData', obj.projectionDrawingStartY);
        end

        function adjustAxisLimits(obj)
            %ADJUSTAXISLIMITS 动态调整坐标轴范围
            ax = obj.animationObjects.axesMain;
            currentXLim = xlim(ax);
            maxWaveX = max(obj.waveDataX, obj.waveHistoryX);
            maxWaveX = max(maxWaveX, obj.waveDrawingEndX);
            if maxWaveX > currentXLim(2) - 0.5
                xlim(ax, [currentXLim(1), maxWaveX + 0.5]);
            end
            currentYLim = ylim(ax);
            minProjectionY = min(obj.projectionDataY, obj.projectionDrawingEndY);
            if minProjectionY < currentYLim(1) + 0.5
                ylim(ax, [minProjectionY - 0.5, currentYLim(2)]);
            end
        end

        function updateStartButton(obj, oldText, newText, enableState)
            %UPDATESTARTBUTTON 更新开始按钮文本和状态（使用命名字段）
            if isfield(obj.animationObjects, 'startButton') && ...
                    ishandle(obj.animationObjects.startButton)
                if strcmp(get(obj.animationObjects.startButton, 'String'), oldText)
                    set(obj.animationObjects.startButton, 'String', newText, ...
                        'Enable', enableState);
                end
            end
        end
    end

    methods
        % ========== 公共回调 ==========

        function toggleStartPoint(obj, value)
            obj.startFromNegativePiHalf = value;
            obj.resetAnimation();
        end

        function toggleReverseRotation(obj, value)
            obj.reverseRotation = value;
            obj.resetAnimation();
        end

        function updatePeriods(obj, value)
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

% ========== 局部辅助函数 ==========

function out = ternary(cond, trueVal, falseVal)
%TERNARY 简单的三目运算符模拟
if cond
    out = trueVal;
else
    out = falseVal;
end
end
