classdef FIDFourierTransformAnimation < BaseAnimation
    %FIDFOURIERTRANSFORMANIMATION NMR FID 信号与傅里叶变换的3D动画演示
    %   演示30 MHz谱仪上3 Hz共振信号的宏观磁化矢量演化过程：
    %     子图1——3D轨迹：磁化矢量 M(t) 在 (Mx, My, Mz) 空间的螺旋运动
    %     子图2——2D投影：Mxy 横向分量在复平面上的衰减螺旋（FID轨迹）
    %     子图3——频谱：渐进累积的傅里叶变换谱，展示峰的形成过程
    %
    %   支持多次采集（扫描累加）展示信噪比改善效果。

    properties
        % ---- 物理参数 ----
        MHz              (1,1) double = 30       % 谱仪频率 (MHz)
        f0               (1,1) double = 3        % 共振偏移频率 (Hz) = MHz/10
        T2star           (1,1) double = 1.5      % 横向弛豫时间 (s)
        T1               (1,1) double = 3.0      % 纵向弛豫时间 (s)
        M0               (1,1) double = 1.0      % 平衡磁化强度
        nScans           (1,1) double = 1        % 采集次数 (1-64)
        dt               (1,1) double = 0.005    % 采样间隔 (s)，由 f0 自动计算
        tEnd             (1,1) double = 5.0      % 采集总时长 (s)
        noiseStd         (1,1) double = 0.15     % 单次采集噪声标准差
        showAccumulation (1,1) logical = false    % 是否显示逐扫描累加过程
        framesPerScan    (1,1) double = 300      % 单次扫描帧数（动态计算）
        lastAccumScan    (1,1) double = -1        % 上次累加扫描号
        hasAnimationRun  (1,1) logical = false    % 动画是否至少运行过一次
        showSecondPeak   (1,1) logical = false    % 是否显示第二共振频率
        ratioSecondPeak  (1,1) double = 1.0       % 第二峰相对第一峰的振幅比

        % ---- 信号数据 ----
        t                              % 时间轴
        fidClean                       % 无噪声FID复数信号（总信号）
        fidComp1                       % 分量1：0.1 ppm 无噪声FID
        fidComp2                       % 分量2：0.213 ppm 无噪声FID
        f2                             % 第二共振频率 (Hz)
        fidArray                       % 各次扫描的带噪FID (nScans × nPts)
        fidAveraged                    % 平均后的FID
        spectrum                       % 渐进累积的频谱
        spectrumHistory                % 频谱历史用于动画
    end

    methods
        function obj = FIDFourierTransformAnimation()
            %FIDFOURIERTRANSFORMANIMATION 构造函数
            obj@BaseAnimation();
            obj.createGUI();
            obj.initializeAnimationData();
            obj.initGraphics();
            obj.updateInfoText();
            obj.onAnimationStopped();
        end
    end

    methods (Access = protected)
        % ========== 实现抽象方法 ==========

        function createGUI(obj)
            %CREATEGUI 创建图形用户界面
            obj.fig = figure('Name', 'NMR FID 信号与傅里叶变换 3D动画演示', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [50, 50, 1600, 900], ...
                'Color', [0.95, 0.95, 0.95], ...
                'Resize', 'on', ...
                'CloseRequestFcn', @(~,~) obj.closeWindow());

            obj.mainPanel = uipanel('Parent', obj.fig, ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);

            % ---- 控制面板 ----
            obj.controlPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.01, 0.01, 0.76, 0.12], ...
                'Title', '动画控制', ...
                'FontSize', 10, ...
                'BackgroundColor', [0.9, 0.95, 1]);

            % 按钮
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '开始动画', ...
                'Position', [10, 40, 90, 28], 'FontSize', 10, ...
                'FontWeight', 'bold', 'BackgroundColor', [0.7, 0.9, 0.7], ...
                'Callback', @(~,~) obj.startAnimation());
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '暂停/继续', ...
                'Position', [110, 40, 90, 28], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.95, 0.8], ...
                'Callback', @(~,~) obj.toggleAnimation());
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', 'String', '重置', ...
                'Position', [210, 40, 90, 28], 'FontSize', 10, ...
                'BackgroundColor', [1, 0.8, 0.8], ...
                'Callback', @(~,~) obj.resetAnimation());

            % 速度 (0.05x ~ 5x)
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '速度:', ...
                'Position', [310, 42, 35, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], 'HorizontalAlignment', 'left');
            obj.animationObjects.speedSlider = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'slider', 'Position', [345, 42, 140, 20], ...
                'Min', 0.5, 'Max', 50, 'Value', 3, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.onSpeedChanged(get(src, 'Value')));
            obj.animationObjects.speedLabel = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '0.3x', ...
                'Position', [490, 42, 40, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], 'HorizontalAlignment', 'left');

            % 第二峰
            obj.animationObjects.secondPeakCheck = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'checkbox', 'String', '第二峰(0.213 ppm)', ...
                'Position', [535, 42, 120, 20], 'FontSize', 9, ...
                'Value', obj.showSecondPeak, ...
                'BackgroundColor', [0.9, 0.95, 1], ...
                'Callback', @(src,~) obj.toggleSecondPeak(get(src, 'Value')));
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '比例:', ...
                'Position', [655, 42, 30, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9, 0.95, 1], 'HorizontalAlignment', 'left');
            ratioOpts = [1/3 0.5 1 2 3];
            obj.animationObjects.ratioPopup = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'popupmenu', 'String', {'1:3','1:2','1:1','2:1','3:1'}, ...
                'Position', [685, 42, 55, 22], 'FontSize', 9, ...
                'Value', 3, 'BackgroundColor', [1,1,1], ...
                'Callback', @(src,~) obj.updateRatio(ratioOpts(get(src, 'Value'))));

            % 底部行 (整体右移，与上方"速度:"标签对齐 x=310)
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', 'MHz:', ...
                'Position', [310, 10, 35, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9,0.95,1], 'HorizontalAlignment', 'left');
            mhzOpts = [30 60 90 300 400 600];
            obj.animationObjects.mhzPopup = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'popupmenu', ...
                'String', arrayfun(@(n) sprintf('%d',n), mhzOpts, 'UniformOutput',false), ...
                'Position', [345, 10, 55, 22], 'FontSize', 9, ...
                'Value', 1, 'BackgroundColor', [1,1,1], ...
                'Callback', @(src,~) obj.updateMHz(mhzOpts(get(src, 'Value'))));
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', 'NS:', ...
                'Position', [405, 10, 25, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9,0.95,1], 'HorizontalAlignment', 'left');
            nsOpts = [1 2 4 8 16 32 64];
            obj.animationObjects.scanPopup = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'popupmenu', ...
                'String', arrayfun(@(n) sprintf('%d',n), nsOpts, 'UniformOutput',false), ...
                'Position', [430, 10, 50, 22], 'FontSize', 9, ...
                'Value', 1, 'BackgroundColor', [1,1,1], ...
                'Callback', @(src,~) obj.updateScans(nsOpts(get(src, 'Value'))));
            obj.animationObjects.accumCheckbox = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'checkbox', 'String', '显示扫描累加过程', ...
                'Position', [490, 10, 150, 20], 'FontSize', 9, ...
                'Value', obj.showAccumulation, ...
                'BackgroundColor', [0.9,0.95,1], ...
                'Callback', @(src,~) obj.toggleAccumulation(get(src, 'Value')));
            obj.animationObjects.infoText = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'text', 'String', '', ...
                'Position', [650, 10, 500, 20], 'FontSize', 9, ...
                'BackgroundColor', [0.9,0.95,1], 'HorizontalAlignment', 'left');

            % ---- 显示面板 ----
            obj.animationObjects.displayPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.01, 0.14, 0.76, 0.85], ...
                'Title', sprintf('NMR FID 宏观磁化矢量演化 (%d MHz)', obj.MHz), ...
                'FontSize', 11, 'BackgroundColor', [1, 1, 1]);

            % ---- 右侧信息面板 ----
            infoPanel = uipanel('Parent', obj.mainPanel, ...
                'Position', [0.78, 0.01, 0.21, 0.98], ...
                'Title', '参数与说明', 'FontSize', 10, ...
                'BackgroundColor', [0.97, 0.97, 0.97]);
            % 参数状态文本框
            obj.animationObjects.paramText = uicontrol('Parent', infoPanel, ...
                'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.03, 0.51, 0.94, 0.47], ...
                'String', '', 'FontSize', 9, 'FontName', 'Microsoft YaHei', ...
                'HorizontalAlignment', 'left', 'BackgroundColor', [1,1,1], ...
                'Max', 100, 'Min', 0, 'Enable', 'on', ...
                'Callback', @(src,~) set(src,'String', obj.buildParamText()));
            % 图例说明文本框
            obj.animationObjects.legendText = uicontrol('Parent', infoPanel, ...
                'Style', 'edit', 'Units', 'normalized', ...
                'Position', [0.03, 0.02, 0.94, 0.47], ...
                'String', obj.buildLegendText(), 'FontSize', 9, 'FontName', 'Microsoft YaHei', ...
                'HorizontalAlignment', 'left', 'BackgroundColor', [1,1,1], ...
                'Max', 100, 'Min', 0, 'Enable', 'on', ...
                'Callback', @(src,~) set(src,'String', obj.buildLegendText()));
        end

        function initializeAnimationData(obj)
            %INITIALIZEANIMATIONDATA 初始化/重置所有信号数据
            %   f0=MHz/10 (0.1ppm), dt=1/(20*f0) 确保每周期至少20个采样点
            obj.f0 = obj.MHz / 10;
            obj.dt = 1 / (20 * obj.f0);
            obj.t = (0:obj.dt:obj.tEnd)';
            nPts = length(obj.t);

            % 无噪声FID（复数形式），可选第二共振频率
            envelope = exp(-obj.t / obj.T2star);
            obj.fidComp1 = obj.M0 * exp(1i * 2*pi*obj.f0 * obj.t) .* envelope;
            obj.f2 = 0.213 * obj.MHz;  % 非整数ppm，避免与0.1ppm成谐波关系
            obj.fidComp2 = obj.ratioSecondPeak * obj.M0 * exp(1i * 2*pi*obj.f2 * obj.t) .* envelope;
            if obj.showSecondPeak
                obj.fidClean = obj.fidComp1 + obj.fidComp2;
            else
                obj.fidClean = obj.fidComp1;
                obj.fidComp2 = zeros(size(obj.fidComp1));
            end
            % 动态坐标范围 + 帧率：第二峰启用时扩展
            obj.animationObjects.axisLim = 1.2 * (1 + obj.ratioSecondPeak * obj.showSecondPeak);
            obj.framesPerScan = 300 + 200 * obj.showSecondPeak;  % 第二峰启用时500帧

            % 生成各次扫描数据（带噪声）
            obj.fidArray = zeros(nPts, obj.nScans);
            rng(42);  % 固定随机种子，保证可重复
            for s = 1:obj.nScans
                noise = obj.noiseStd * (randn(nPts, 1) + 1i*randn(nPts, 1));
                obj.fidArray(:, s) = obj.fidClean + noise;
            end

            % 平均后的FID
            obj.fidAveraged = mean(obj.fidArray, 2);

            % 双边频谱映射到化学位移 [0,1] ppm
            N = length(obj.t);
            fs = 1 / obj.dt;
            fBilateral = (-floor(N/2):ceil(N/2)-1)' * fs / N;
            specBilateral = abs(fftshift(fft(obj.fidAveraged)));
            ppmRaw = fBilateral / obj.MHz;
            ppmTarget = linspace(0, 1, 600)';
            obj.animationObjects.ppmAxis = ppmTarget;
            obj.spectrum = interp1(ppmRaw, specBilateral, ppmTarget, 'linear', 0);

            obj.lastAccumScan = -1;

            % 设置总帧数：累加模式 = 扫描数 × 每扫描帧数，否则只放一轮
            if obj.showAccumulation
                obj.totalFrames = obj.nScans * obj.framesPerScan;
            else
                obj.totalFrames = obj.framesPerScan;
            end
        end

        function initGraphics(obj)
            %INITGRAPHICS 初始化2×3布局的图形元素
            %   (1,1)+(2,1) 子图1=3D磁化矢量轨迹（左列，跨两行）
            %   (1,2)       子图2=2D复平面投影（中上）
            %   (1,3)       子图3=FID时域信号（右上，新增）
            %   (2,2)+(2,3) 子图4=FT频谱（下方跨中右两列）
            dp = obj.animationObjects.displayPanel;
            delete(findobj(dp.Children, 'Type', 'axes'));

            % ---- 子图1：3D磁化矢量轨迹（左列，跨两行）----
            ax1 = subplot(2, 3, [1, 4], 'Parent', dp);
            hold(ax1, 'on'); grid(ax1, 'on');
            view(ax1, 30, 25);
            xlabel(ax1, 'M_x'); ylabel(ax1, 'M_y'); zlabel(ax1, 'M_z');
            title(ax1, '3D 磁化矢量轨迹 M(t)', 'FontSize', 11, 'FontWeight', 'bold');

            lim = obj.animationObjects.axisLim;
            plot3(ax1, [-lim, lim], [0, 0], [0, 0], 'k-', 'LineWidth', 0.5);
            plot3(ax1, [0, 0], [-lim, lim], [0, 0], 'k-', 'LineWidth', 0.5);
            plot3(ax1, [0, 0], [0, 0], [0, lim], 'k-', 'LineWidth', 0.5);

            % 分量1向量（青色箭头 + 球）
            obj.animationObjects.vec_c1 = quiver3(ax1, 0, 0, 0, 0, 0, 0, ...
                'Color', [0.0, 0.7, 0.9], 'LineWidth', 1.5, 'MaxHeadSize', 0.2);
            obj.animationObjects.ball_c1 = plot3(ax1, NaN, NaN, NaN, ...
                'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.0, 0.7, 0.9], ...
                'MarkerEdgeColor', 'k');
            % 分量2向量（橙色箭头 + 球）
            obj.animationObjects.vec_c2 = quiver3(ax1, 0, 0, 0, 0, 0, 0, ...
                'Color', [0.9, 0.5, 0.0], 'LineWidth', 1.5, 'MaxHeadSize', 0.2);
            obj.animationObjects.ball_c2 = plot3(ax1, NaN, NaN, NaN, ...
                'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.9, 0.5, 0.0], ...
                'MarkerEdgeColor', 'k');
            % 合成向量（红色粗箭头 + 球 = 实际宏观磁化量）
            obj.animationObjects.magVector = quiver3(ax1, 0, 0, 0, 0, 0, 0, ...
                'r', 'LineWidth', 2.5, 'MaxHeadSize', 0.3);
            obj.animationObjects.currentPoint3D = plot3(ax1, NaN, NaN, NaN, ...
                'ro', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
            % 轨迹线
            obj.animationObjects.traj3D = plot3(ax1, NaN, NaN, NaN, ...
                'b-', 'LineWidth', 1.5);
            obj.animationObjects.traj3D_c1 = plot3(ax1, NaN, NaN, NaN, ...
                ':', 'Color', [0.0, 0.7, 0.9], 'LineWidth', 0.8);
            obj.animationObjects.traj3D_c2 = plot3(ax1, NaN, NaN, NaN, ...
                ':', 'Color', [0.9, 0.5, 0.0], 'LineWidth', 0.8);

            xlim(ax1, [-lim, lim]); ylim(ax1, [-lim, lim]); zlim(ax1, [0, lim]);
            axis(ax1, 'vis3d');
            hold(ax1, 'off');
            obj.animationObjects.ax1 = ax1;

            % ---- 子图2：2D复平面投影（中上）----
            ax2 = subplot(2, 3, 2, 'Parent', dp);
            hold(ax2, 'on'); grid(ax2, 'on'); axis(ax2, 'equal');
            xlabel(ax2, '实部 M_x'); ylabel(ax2, '虚部 M_y');
            title(ax2, '2D 横向投影 (复平面)', 'FontSize', 11, 'FontWeight', 'bold');

            th = linspace(0, 2*pi, 200);
            plot(ax2, cos(th), sin(th), ':', 'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
            plot(ax2, [-lim, lim], [0, 0], 'k-', 'LineWidth', 0.5);
            plot(ax2, [0, 0], [-lim, lim], 'k-', 'LineWidth', 0.5);
            obj.animationObjects.traj2D = plot(ax2, NaN, NaN, 'b-', 'LineWidth', 1.5);
            obj.animationObjects.traj2D_c1 = plot(ax2, NaN, NaN, ...
                ':', 'Color', [0.0, 0.7, 0.9], 'LineWidth', 0.8);
            obj.animationObjects.traj2D_c2 = plot(ax2, NaN, NaN, ...
                ':', 'Color', [0.9, 0.5, 0.0], 'LineWidth', 0.8);
            % 分量球
            obj.animationObjects.ball2D_c1 = plot(ax2, NaN, NaN, ...
                'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.0, 0.7, 0.9], 'MarkerEdgeColor', 'k');
            obj.animationObjects.ball2D_c2 = plot(ax2, NaN, NaN, ...
                'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.9, 0.5, 0.0], 'MarkerEdgeColor', 'k');
            % 合成
            obj.animationObjects.currentPoint2D = plot(ax2, NaN, NaN, ...
                'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
            obj.animationObjects.vec2D = plot(ax2, [0, NaN], [0, NaN], ...
                'r-', 'LineWidth', 1.5);
            obj.animationObjects.vec2D_c1 = plot(ax2, [0, NaN], [0, NaN], ...
                '-', 'Color', [0.0, 0.7, 0.9], 'LineWidth', 1);
            obj.animationObjects.vec2D_c2 = plot(ax2, [0, NaN], [0, NaN], ...
                '-', 'Color', [0.9, 0.5, 0.0], 'LineWidth', 1);
            xlim(ax2, [-lim, lim]); ylim(ax2, [-lim, lim]);
            hold(ax2, 'off');
            obj.animationObjects.ax2 = ax2;

            % ---- 子图3：FID时域信号（右上，新增）----
            ax3 = subplot(2, 3, 3, 'Parent', dp);
            hold(ax3, 'on'); grid(ax3, 'on');
            xlabel(ax3, '时间 (s)'); ylabel(ax3, '信号幅度');
            obj.animationObjects.fidTitle = title(ax3, ...
                'FID 信号', 'FontSize', 11, 'FontWeight', 'bold');

            % 零线
            plot(ax3, [0, obj.tEnd], [0, 0], 'k-', 'LineWidth', 0.5);
            % 包络线（后续动态绘制）
            obj.animationObjects.envPos = plot(ax3, NaN, NaN, 'r--', 'LineWidth', 1);
            obj.animationObjects.envNeg = plot(ax3, NaN, NaN, 'r--', 'LineWidth', 1);
            % FID波形
            obj.animationObjects.fidWave = plot(ax3, NaN, NaN, 'b-', 'LineWidth', 1.2);
            % 分量FID波形（虚线）
            obj.animationObjects.fidWave_c1 = plot(ax3, NaN, NaN, ...
                ':', 'Color', [0.0, 0.7, 0.9], 'LineWidth', 0.8);
            obj.animationObjects.fidWave_c2 = plot(ax3, NaN, NaN, ...
                ':', 'Color', [0.9, 0.5, 0.0], 'LineWidth', 0.8);
            % 当前时间竖线
            obj.animationObjects.timeLine = plot(ax3, [0, 0], [-lim, lim], ...
                'k:', 'LineWidth', 1);
            xlim(ax3, [0, obj.tEnd]); ylim(ax3, [-lim, lim]);
            hold(ax3, 'off');
            obj.animationObjects.ax3 = ax3;

            % ---- 子图4：FT频谱（下方，跨中右两列）----
            ax4 = subplot(2, 3, [5, 6], 'Parent', dp);
            hold(ax4, 'on'); grid(ax4, 'on');
            xlabel(ax4, '化学位移 (ppm)'); ylabel(ax4, '幅度');
            title(ax4, 'FT 频谱', 'FontSize', 11, 'FontWeight', 'bold');

            ppmFull = obj.animationObjects.ppmAxis;
            specFull = obj.spectrum;
            obj.animationObjects.refSpec = plot(ax4, ppmFull, specFull, ...
                ':', 'Color', [0.6, 0.6, 0.6], 'LineWidth', 1.5);
            obj.animationObjects.currentSpec = plot(ax4, ppmFull, zeros(size(ppmFull)), ...
                'b-', 'LineWidth', 2);
            % 用 findpeaks 检测峰（最小间距 0.05 ppm，最小高度 10% 最高峰）
            % 手动查找峰：最高峰 → 屏蔽 → 次高峰
            [~, pk1] = max(specFull);
            p1ppm = ppmFull(pk1); p1val = specFull(pk1);
            % 屏蔽第一峰 ±0.05 ppm 区域
            mask = abs(ppmFull - p1ppm) > 0.05;
            specMasked = specFull; specMasked(~mask) = 0;
            [p2val, pk2] = max(specMasked);
            p2ppm = ppmFull(pk2);
            nPks = 1 + (p2val > p1val * 0.1);  % 第二峰需超过第一峰10%
            obj.animationObjects.peakMarkers = gobjects(nPks, 1);
            % 峰1
            obj.animationObjects.peakMarkers(1) = ...
                stem(ax4, p1ppm, p1val, 'r', 'LineWidth', 1.5, ...
                'MarkerSize', 6, 'MarkerFaceColor', 'r');
            set(obj.animationObjects.peakMarkers(1), 'Visible', 'off');
            text(ax4, p1ppm, p1val*1.15, sprintf('%.2f ppm\n(%.1f Hz)', p1ppm, p1ppm*obj.MHz), ...
                'FontSize', 8, 'Color', 'r', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
            if nPks > 1
                obj.animationObjects.peakMarkers(2) = ...
                    stem(ax4, p2ppm, p2val, 'r', 'LineWidth', 1.5, ...
                    'MarkerSize', 6, 'MarkerFaceColor', 'r');
                set(obj.animationObjects.peakMarkers(2), 'Visible', 'off');
                text(ax4, p2ppm, p2val*1.15, sprintf('%.2f ppm\n(%.1f Hz)', p2ppm, p2ppm*obj.MHz), ...
                    'FontSize', 8, 'Color', 'r', 'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'bottom');
            end
            xlim(ax4, [0, 1]);
            ylim(ax4, [0, max(specFull)*1.15]);
            set(ax4, 'XDir', 'reverse');  % NMR惯例：高ppm(低频)在右，低ppm(高频)在左
            hold(ax4, 'off');
            obj.animationObjects.ax4 = ax4;

            % 累加次数标签（左上角）
            obj.animationObjects.accumLabel = uicontrol('Parent', dp, ...
                'Style', 'text', 'String', '', ...
                'Units', 'normalized', 'Position', [0.01, 0.92, 0.22, 0.06], ...
                'FontSize', 13, 'FontWeight', 'bold', ...
                'ForegroundColor', [0.8, 0.2, 0.2], ...
                'BackgroundColor', [1, 1, 0.9], ...
                'HorizontalAlignment', 'center');

            % 进度文本
            obj.animationObjects.progressText = uicontrol('Parent', dp, ...
                'Style', 'text', 'String', '就绪', ...
                'Units', 'normalized', 'Position', [0.01, 0.01, 0.4, 0.04], ...
                'FontSize', 9, 'BackgroundColor', [1, 1, 1], ...
                'HorizontalAlignment', 'left');
        end

        function updateAnimationFrame(obj)
            %UPDATEANIMATIONFRAME 更新一帧动画
            if obj.currentFrame > obj.totalFrames
                obj.stopAnimation();
                return;
            end

            nPts = length(obj.t);

            if obj.showAccumulation
                % ---- 逐扫描累加模式 ----
                % 每扫描：左侧3D/FID播当前扫描原始带噪数据，
                % 右侧2D/FT在整次扫描期间保持累加平均（扫描完成时才更新）
                currentScan = floor((obj.currentFrame - 1) / obj.framesPerScan) + 1;
                currentScan = min(currentScan, obj.nScans);
                frameInScan = mod(obj.currentFrame - 1, obj.framesPerScan) + 1;
                idx = max(round(frameInScan * nPts / obj.framesPerScan), 2);

                fidRaw   = obj.fidArray(:, currentScan);             % 当前扫描原始噪声FID
                % 累加结果 = 前(currentScan-1)次扫描的平均（本轮完成后右侧才刷新）
                if currentScan > 1
                    fidAccum = mean(obj.fidArray(:, 1:currentScan-1), 2);
                else
                    fidAccum = zeros(length(obj.t), 1);
                end
            else
                % ---- 直接看最终平均结果 ----
                currentScan = obj.nScans;
                idx = max(round(obj.currentFrame * nPts / obj.totalFrames), 2);
                fidRaw   = obj.fidAveraged;
                fidAccum = obj.fidAveraged;
            end

            tNow = obj.t(idx);

            % 更新进度文本
            if ishandle(obj.animationObjects.progressText)
                if obj.showAccumulation && obj.nScans > 1
                    completed = currentScan - 1;
                    set(obj.animationObjects.progressText, 'String', ...
                        sprintf('扫描 %d/%d | t = %.2f s | 已完成累加 %d 次', ...
                        currentScan, obj.nScans, tNow, completed));
                else
                    set(obj.animationObjects.progressText, 'String', ...
                        sprintf('t = %.2f s (%.0f%%)  |  NS = %d', ...
                        tNow, 100*idx/nPts, obj.nScans));
                end
            end

            nFull = length(obj.t);

            % 左列(3D) = 逐帧绘制当前扫描的原始带噪磁化矢量轨迹
            updateTrajectory3D(obj, idx, fidRaw);

            if obj.showAccumulation
                % 累加模式：仅扫描边界刷新右侧（避免频谱跳变）
                if currentScan ~= obj.lastAccumScan
                    updateProjection2D(obj, nFull, fidAccum);
                    updateFIDSignal(obj, nFull, tNow, fidAccum);
                    updateSpectrum(obj, nFull, fidAccum);
                    obj.lastAccumScan = currentScan;
                end
            else
                % 快速模式：所有图形随3D轨迹同步渐进绘制
                updateProjection2D(obj, idx, fidAccum);
                updateFIDSignal(obj, idx, tNow, fidAccum);
                updateSpectrum(obj, idx, fidAccum);
            end

            % 更新累加次数显示
            obj.updateAccumLabel(currentScan);
        end

        function onAnimationStarted(obj)
            obj.updateButtonText('开始动画', '动画中...', 'off');
            obj.hasAnimationRun = true;
            obj.refreshParamText();
        end

        function onAnimationStopped(obj)
            obj.updateButtonText('动画中...', '开始动画', 'on');
            obj.refreshParamText();
            if ishandle(obj.animationObjects.progressText)
                set(obj.animationObjects.progressText, 'String', '就绪');
            end
            if ~obj.hasAnimationRun, obj.updateAccumLabel(0); return; end
            % 累加模式结束时刷新右侧最终结果
            if obj.showAccumulation
                nFull = length(obj.t);
                updateProjection2D(obj, nFull, obj.fidAveraged);
                updateFIDSignal(obj, nFull, 0, obj.fidAveraged);
                updateSpectrum(obj, nFull, obj.fidAveraged);
                if ishandle(obj.animationObjects.accumLabel)
                    set(obj.animationObjects.accumLabel, 'String', ...
                        sprintf('累加: %d / %d (完成)', obj.nScans, obj.nScans));
                end
            else
                obj.updateAccumLabel(0);
            end
        end
    end

    methods (Access = private)
        % ========== 子图更新函数 ==========

        function updateTrajectory3D(obj, idx, fid)
            %UPDATETRAJECTORY3D 更新3D磁化矢量：分量箭头+球+轨迹+合成矢量
            Mx = real(fid(1:idx));
            My = imag(fid(1:idx));
            Mz = obj.M0 * (1 - exp(-obj.t(1:idx) / obj.T1));
            tIdx = obj.t(1:idx);

            if idx > 1
                % 合成轨迹
                obj.safeSet(obj.safeGetHandle('traj3D', 0), ...
                    'XData', Mx, 'YData', My, 'ZData', Mz);
                % 分量轨迹 + 向量 + 球
                if obj.showSecondPeak
                    c1 = obj.fidComp1(1:idx); c2 = obj.fidComp2(1:idx);
                    Mz_c = obj.M0 * (1 - exp(-tIdx / obj.T1));
                    obj.safeSet(obj.safeGetHandle('traj3D_c1', 0), ...
                        'XData', real(c1), 'YData', imag(c1), 'ZData', Mz_c);
                    obj.safeSet(obj.safeGetHandle('traj3D_c2', 0), ...
                        'XData', real(c2), 'YData', imag(c2), 'ZData', Mz_c);
                    % 分量箭头
                    obj.safeSet(obj.safeGetHandle('vec_c1', 0), ...
                        'XData', 0, 'YData', 0, 'ZData', 0, ...
                        'UData', real(c1(end)), 'VData', imag(c1(end)), 'WData', Mz_c(end));
                    obj.safeSet(obj.safeGetHandle('vec_c2', 0), ...
                        'XData', 0, 'YData', 0, 'ZData', 0, ...
                        'UData', real(c2(end)), 'VData', imag(c2(end)), 'WData', Mz_c(end));
                    % 分量球
                    obj.safeSet(obj.safeGetHandle('ball_c1', 0), ...
                        'XData', real(c1(end)), 'YData', imag(c1(end)), 'ZData', Mz_c(end));
                    obj.safeSet(obj.safeGetHandle('ball_c2', 0), ...
                        'XData', real(c2(end)), 'YData', imag(c2(end)), 'ZData', Mz_c(end));
                end
            end

            % 合成矢量
            obj.safeSet(obj.safeGetHandle('magVector', 0), ...
                'XData', 0, 'YData', 0, 'ZData', 0, ...
                'UData', Mx(end), 'VData', My(end), 'WData', Mz(end));
            obj.safeSet(obj.safeGetHandle('currentPoint3D', 0), ...
                'XData', Mx(end), 'YData', My(end), 'ZData', Mz(end));
        end

        function updateProjection2D(obj, idx, fid)
            %UPDATEPROJECTION2D 更新2D复平面投影（含分量轨迹+向量+球）
            Mx = real(fid(1:idx));
            My = imag(fid(1:idx));

            obj.safeSet(obj.safeGetHandle('traj2D', 0), ...
                'XData', Mx, 'YData', My);
            if obj.showSecondPeak
                c1 = obj.fidComp1(1:idx); c2 = obj.fidComp2(1:idx);
                x1=real(c1); y1=imag(c1); x2=real(c2); y2=imag(c2);
                obj.safeSet(obj.safeGetHandle('traj2D_c1', 0), 'XData', x1, 'YData', y1);
                obj.safeSet(obj.safeGetHandle('traj2D_c2', 0), 'XData', x2, 'YData', y2);
                obj.safeSet(obj.safeGetHandle('vec2D_c1', 0), ...
                    'XData', [0, x1(end)], 'YData', [0, y1(end)]);
                obj.safeSet(obj.safeGetHandle('vec2D_c2', 0), ...
                    'XData', [0, x2(end)], 'YData', [0, y2(end)]);
                obj.safeSet(obj.safeGetHandle('ball2D_c1', 0), ...
                    'XData', x1(end), 'YData', y1(end));
                obj.safeSet(obj.safeGetHandle('ball2D_c2', 0), ...
                    'XData', x2(end), 'YData', y2(end));
            end
            obj.safeSet(obj.safeGetHandle('currentPoint2D', 0), ...
                'XData', Mx(end), 'YData', My(end));
            obj.safeSet(obj.safeGetHandle('vec2D', 0), ...
                'XData', [0, Mx(end)], 'YData', [0, My(end)]);
        end

        function updateFIDSignal(obj, idx, tNow, fid)
            %UPDATEFIDSIGNAL 更新FID时域信号波形（含分量虚线）
            tVals = obj.t(1:idx);
            fidReal = real(fid(1:idx));

            obj.safeSet(obj.safeGetHandle('fidWave', 0), ...
                'XData', tVals, 'YData', fidReal);
            if obj.showSecondPeak
                c1 = obj.fidComp1(1:idx); c2 = obj.fidComp2(1:idx);
                obj.safeSet(obj.safeGetHandle('fidWave_c1', 0), ...
                    'XData', tVals, 'YData', real(c1));
                obj.safeSet(obj.safeGetHandle('fidWave_c2', 0), ...
                    'XData', tVals, 'YData', real(c2));
            end

            env = exp(-tVals / obj.T2star);
            obj.safeSet(obj.safeGetHandle('envPos', 0), ...
                'XData', tVals, 'YData', env);
            obj.safeSet(obj.safeGetHandle('envNeg', 0), ...
                'XData', tVals, 'YData', -env);

            nFull = length(obj.t);
            yl = obj.animationObjects.axisLim;
            if idx < nFull
                obj.safeSet(obj.safeGetHandle('timeLine', 0), ...
                    'XData', [tNow, tNow], 'YData', [-yl, yl], 'Visible', 'on');
            else
                obj.safeSet(obj.safeGetHandle('timeLine', 0), 'Visible', 'off');
            end
        end

        function updateSpectrum(obj, idx, fid)
            %UPDATESPECTRUM 双边FFT映射到[0,1] ppm
            if idx < 8, return; end

            nFull = length(obj.t);
            segment = [fid(1:idx); zeros(nFull - idx, 1)];
            specBilateral = abs(fftshift(fft(segment)));
            fs = 1/obj.dt;
            fBilateral = (-floor(nFull/2):ceil(nFull/2)-1)' * fs / nFull;
            spec = interp1(fBilateral/obj.MHz, specBilateral, ...
                obj.animationObjects.ppmAxis, 'linear', 0);

            obj.safeSet(obj.safeGetHandle('currentSpec', 0), ...
                'XData', obj.animationObjects.ppmAxis, 'YData', spec);
            if ishandle(obj.animationObjects.ax4)
                xlim(obj.animationObjects.ax4, [0, 1]);
            end

            if idx > nFull * 0.8
                ppmA = obj.animationObjects.ppmAxis;
                [~, pk1] = max(spec); p1ppm = ppmA(pk1);
                mask = abs(ppmA - p1ppm) > 0.05;
                s2 = spec; s2(~mask) = 0; [~, pk2] = max(s2);
                nMarks = length(obj.animationObjects.peakMarkers);
                if nMarks >= 1 && ishandle(obj.animationObjects.peakMarkers(1))
                    set(obj.animationObjects.peakMarkers(1), ...
                        'XData', p1ppm, 'YData', spec(pk1), 'Visible', 'on');
                end
                if nMarks >= 2 && ishandle(obj.animationObjects.peakMarkers(2))
                    set(obj.animationObjects.peakMarkers(2), ...
                        'XData', ppmA(pk2), 'YData', spec(pk2), 'Visible', 'on');
                end
            end
        end
    end

    methods
        % ========== 公共回调 ==========

        function onSpeedChanged(obj, sliderVal)
            %ONSPEEDCHANGED 滑块变化时更新速度标签并委托基类处理速度
            speedX = sliderVal / 10;  % 映射 0.5→0.05x, 50→5x
            set(obj.animationObjects.speedLabel, 'String', sprintf('%.1fx', speedX));
            obj.updateAnimationSpeed(sliderVal);
        end

        function updateScans(obj, n)
            %UPDATESCANS 更新NMR采集次数并重新生成数据
            obj.nScans = n;
            obj.resetAnimation();
        end

        function updateMHz(obj, m)
            %UPDATEMHZ 切换NMR谱仪频率，自动重算 f0、dt
            obj.MHz = m;
            obj.resetAnimation();
            obj.updateInfoText();
            % 更新面板标题
            if isfield(obj.animationObjects, 'displayPanel') && ishandle(obj.animationObjects.displayPanel)
                set(obj.animationObjects.displayPanel, 'Title', ...
                    sprintf('NMR FID 宏观磁化矢量演化 (%d MHz)', obj.MHz));
            end
            % 更新FID子图标题
            if isfield(obj.animationObjects, 'fidTitle') && ishandle(obj.animationObjects.fidTitle)
                set(obj.animationObjects.fidTitle, 'String', 'FID 信号');
            end
        end

        function updateInfoText(obj)
            %UPDATEINFOTEXT 刷新底部参数信息文本（f0/dt 已由 initializeAnimationData 更新）
            if ~isfield(obj.animationObjects, 'infoText') || ...
                    ~ishandle(obj.animationObjects.infoText)
                return;
            end
            set(obj.animationObjects.infoText, 'String', ...
                sprintf('仪器: %d MHz | 偏移: %.1f Hz (0.1 ppm) | T2* = %.1f s | 采样率: %.0f Hz | 点数: %d', ...
                obj.MHz, obj.f0, obj.T2star, 1/obj.dt, round(obj.tEnd/obj.dt)+1));
            % 更新右侧参数文本框
            if isfield(obj.animationObjects, 'paramText') && ishandle(obj.animationObjects.paramText)
                set(obj.animationObjects.paramText, 'String', obj.buildParamText());
            end
        end

        function toggleAccumulation(obj, val)
            %TOGGLEACCUMULATION 切换累加模式：勾选时自动最大速度，取消恢复默认
            obj.showAccumulation = val;
            if val
                set(obj.animationObjects.speedSlider, 'Value', 50);
                obj.onSpeedChanged(50);
            else
                set(obj.animationObjects.speedSlider, 'Value', 3);
                obj.onSpeedChanged(3);
            end
            obj.resetAnimation();
        end

        function toggleSecondPeak(obj, val)
            %TOGGLESECONDPEAK 切换第二共振频率 (0.213 ppm) 的开关
            obj.showSecondPeak = val;
            obj.resetAnimation();
        end

        function updateRatio(obj, r)
            %UPDATERATIO 更新第二峰与第一峰的振幅比
            obj.ratioSecondPeak = r;
            if obj.showSecondPeak
                obj.resetAnimation();
            end
        end

        function txt = buildParamText(obj)
            %BUILDPARAMTEXT 构建当前参数状态文本
            if obj.showSecondPeak
                ratioStr = sprintf('%.1f:1', obj.ratioSecondPeak);
                peakStr = sprintf('2个 (0.10 + 0.213 ppm)');
            else
                ratioStr = '--';
                peakStr = '1个 (0.10 ppm)';
            end
            if obj.showAccumulation, accStr = '逐扫描累加'; else, accStr = '直接平均'; end
            if obj.isAnimating, stateStr = '运行中...'; else, stateStr = '已停止'; end
            txt = sprintf([ ...
                '=== 当前参数 ===\n' ...
                '谱仪频率: %d MHz\n' ...
                '共振峰数: %s\n' ...
                '振幅比例: %s\n' ...
                '采集次数: %d\n' ...
                '采样间隔: %.4f s\n' ...
                '采样点数: %d\n' ...
                'Nyquist : %.0f Hz (%.0f ppm)\n' ...
                '累加模式: %s\n\n' ...
                '=== 动画状态 ===\n' ...
                '%s'], ...
                obj.MHz, peakStr, ratioStr, obj.nScans, ...
                obj.dt, length(obj.t), ...
                0.5/obj.dt, 0.5/obj.dt/obj.MHz, ...
                accStr, stateStr);
        end

        function txt = buildLegendText(obj)
            %BUILDLEGENDTEXT 构建图例说明文本
            txt = sprintf([ ...
                '=== 子图说明 ===\n' ...
                '【左上 3D轨迹】M(t)在(Mx,My,Mz)空间的螺旋\n' ...
                ' 红球=实际磁化量 青球=0.10ppm 橙球=0.213ppm\n' ...
                ' 虚线=各分量轨迹\n' ...
                '【中上 2D投影】Mxy复平面衰减螺旋\n' ...
                ' 灰圈=单位圆参考\n' ...
                '【右上 FID】时域实部(Mx投影)\n' ...
                ' 红虚线=衰减包络 ±e^{-t/T2*}\n' ...
                ' 虚线=各分量波形\n' ...
                '【下方 FT频谱】傅里叶变换频域谱\n' ...
                ' 灰虚线=最终参考谱 蓝实线=渐进谱 X轴反向\n\n' ...
                '=== 参数说明 ===\n' ...
                'MHz:谱仪频率 f(Hz)=δ(ppm)×MHz\n' ...
                'NS:累加次数 信噪比∝√NS\n' ...
                'T2*=%.1fs T1=%.1fs\n' ...
                '实际NMR频率(%.0f~%.0f Hz)远高于可见\n' ...
                '范围，动画显示下变频后的差频信号\n\n' ...
                '=== 动画说明 ===\n' ...
                '累加模式:每扫描播放完整FID采集，右侧\n' ...
                '扫描完成后刷新，展示SNR逐步改善\n' ...
                '快速模式:所有图形随3D轨迹同步渐进'], ...
                obj.T2star, obj.T1, ...
                obj.MHz*1e6*0.9, obj.MHz*1e6*1.1);
        end

        function refreshParamText(obj)
            if isfield(obj.animationObjects, 'paramText') && ishandle(obj.animationObjects.paramText)
                set(obj.animationObjects.paramText, 'String', obj.buildParamText());
            end
        end

        function updateAccumLabel(obj, currentScan)
            %UPDATEACCUMLABEL 更新左上角累加次数显示
            if ~isfield(obj.animationObjects, 'accumLabel') || ...
                    ~ishandle(obj.animationObjects.accumLabel)
                return;
            end
            completed = currentScan - 1;  % 当前正在跑的扫描还未完成
            if obj.showAccumulation && obj.nScans > 1 && currentScan > 0
                set(obj.animationObjects.accumLabel, 'String', ...
                    sprintf('累加: %d / %d', completed, obj.nScans));
            else
                set(obj.animationObjects.accumLabel, 'String', '');
            end
        end
    end
end
