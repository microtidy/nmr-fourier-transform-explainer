classdef FourierTransformExplainer < handle
    % 傅里叶变换讲解器 - MATLAB GUI应用程序

    properties
        % GUI组件
        fig
        mainPanel
        controlPanel
        displayPanel
        axesDisplay

        % 布局控制（可拖动分隔条调整左右宽度比例）
        controlFrac            % 控制面板占总宽度的比例
        splitter               % 可拖动的分隔条
        isDraggingSplitter     % 是否正在拖动分隔条

        % 新添加的组件
        summaryPanel     % 汇总面板
        summaryText      % 汇总文本框

        % 控制组件
        stepButtons
        explanationText
        currentStep
        show3DCheckbox

        % 动画对象存储
        currentAnimation

        % 数据存储
        t
        f
        signals

        % 各步骤标题（CSV列2）——用于按钮标签
        stepTitles

        % 各步骤操作说明（CSV列3）——显示在控制面板 explanationText 中
        explanationContents

        % 各步骤详细讲解（CSV列4）——由"步骤说明"按钮弹出
        operationInstructions

        % 各步骤汇总文本（CSV列5）——显示在底部 summaryText 中
        summaryContents

        % 学习指南全文（CSV的LG行列3）——由"学习指南"按钮弹出
        learningGuideContent
    end

    methods
        function obj = FourierTransformExplainer()
            % 构造函数 - 创建主界面
            obj.loadDisplayTexts();     % 从CSV文件加载所有显示文本
            obj.createGUI();
            obj.initializeData();
            obj.currentStep = 1;
            obj.updateDisplay();
        end

        function createGUI(obj)
            % 创建图形用户界面

            % 主窗口：依据屏幕尺寸取一个较大的默认值，尽量扩大显示区
            scr = get(0, 'ScreenSize');
            figW = min(1320, round(scr(3) * 0.92));
            figH = min(840,  round(scr(4) * 0.90));
            figW = max(figW, 1000);
            figH = max(figH, 660);
            figX = max(20, round((scr(3) - figW) / 2));
            figY = max(20, round((scr(4) - figH) / 2) - 20);

            obj.controlFrac = 0.24;          % 控制面板默认宽度比例

            obj.fig = figure('Name', 'NMR傅里叶变换原理讲解器', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [figX, figY, figW, figH], ...
                'Color', [0.95, 0.95, 0.95], ...
                'Resize', 'on', ...
                'SizeChangedFcn', @(~, ~) obj.onFigureResize());

            % 主面板
            obj.mainPanel = uipanel('Parent', obj.fig, ...
                'Units', 'normalized', ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);

            % 控制面板
            obj.controlPanel = uipanel('Parent', obj.mainPanel, ...
                'Units', 'normalized', ...
                'Title', '控制面板', ...
                'FontSize', 12, ...
                'BackgroundColor', [0.9, 0.9, 0.9]);

            % 可拖动的分隔条：调整控制面板与显示区的宽度比例
            obj.splitter = uicontrol('Parent', obj.mainPanel, ...
                'Style', 'text', ...
                'Units', 'normalized', ...
                'String', '', ...
                'BackgroundColor', [0.72, 0.76, 0.86], ...
                'Enable', 'on', ...
                'TooltipString', '拖动可调整左右宽度比例', ...
                'ButtonDownFcn', @(src, ~) obj.startSplitDrag());

            % 显示面板
            obj.displayPanel = uipanel('Parent', obj.mainPanel, ...
                'Units', 'normalized', ...
                'Title', '原理展示', ...
                'FontSize', 12, ...
                'BackgroundColor', [1, 1, 1]);

            % 创建汇总面板（放在显示面板下方）
            obj.summaryPanel = uipanel('Parent', obj.mainPanel, ...
                'Units', 'normalized', ...
                'Title', '核心要点汇总', ...
                'FontSize', 11, ...
                'BackgroundColor', [0.95, 0.95, 0.95]);

            % 创建汇总文本框
            obj.summaryText = uicontrol('Parent', obj.summaryPanel, ...
                'Style', 'edit', ...
                'Units', 'normalized', ...
                'Position', [0.02, 0.02, 0.96, 0.96], ...
                'FontSize', 10, ...
                'BackgroundColor', [1, 1, 1], ...
                'ForegroundColor', [0.1, 0.1, 0.1], ...
                'HorizontalAlignment', 'left', ...
                'Max', 100, ...           % 允许多行文本
                'Min', 0, ...             % 允许多行文本
                'Enable', 'on', ...            % on=可选择复制；Enter 键恢复原文
                'SliderStep', [0.01, 0.1], ...
                'Callback', @(src,~) obj.updateSummaryText(obj.currentStep), ...
                'String', '选择步骤查看核心要点汇总...');

            % 创建步骤按钮（按钮文本从 CSV 文件加载，由 loadDisplayTexts 初始化）
            % 使用归一化坐标，随窗口缩放自动调整大小与位置
            nSteps = length(obj.stepTitles);
            obj.stepButtons = gobjects(nSteps, 1);
            btnTop = 0.955;
            btnBottom = 0.545;
            btnGap = 0.004;
            btnH = (btnTop - btnBottom - (nSteps-1)*btnGap) / nSteps;
            for i = 1:nSteps
                posY = btnTop - i*btnH - (i-1)*btnGap;
                obj.stepButtons(i) = uicontrol('Parent', obj.controlPanel, ...
                    'Style', 'pushbutton', ...
                    'Units', 'normalized', ...
                    'String', sprintf('%d: %s', i, obj.stepTitles{i}), ...
                    'Position', [0.03, posY, 0.94, btnH], ...
                    'FontSize', 9, ...
                    'Callback', @(src,event) obj.selectStep(i));
            end

            % 添加解释文本框
            obj.explanationText = uicontrol('Parent', obj.controlPanel, ...
                'Style', 'edit', ...
                'Units', 'normalized', ...
                'Position', [0.03, 0.02, 0.94, 0.465], ...
                'String', '选择步骤查看详细讲解', ...
                'FontSize', 9, ...
                'BackgroundColor', [0.95, 0.95, 0.95], ...
                'HorizontalAlignment', 'left', ...
                'Max', 10, ...      % 允许多行文本
                'Min', 0, ...       % 允许多行文本
                'Enable', 'on'); % 设置为不可编辑，但允许选择和复制

            % 添加学习指南按钮
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', ...
                'String', '📚 学习指南', ...
                'Units', 'normalized', ...
                'Position', [0.03, 0.495, 0.46, 0.042], ...
                'FontSize', 9, ...
                'BackgroundColor', [0.8, 0.9, 1], ...
                'Callback', @(src,event) obj.showLearningGuide());

            % 添加步骤说明按钮
            uicontrol('Parent', obj.controlPanel, ...
                'Style', 'pushbutton', ...
                'String', '📋 步骤说明', ...
                'Units', 'normalized', ...
                'Position', [0.51, 0.495, 0.46, 0.042], ...
                'FontSize', 9, ...
                'BackgroundColor', [0.9, 1, 0.9], ...
                'Callback', @(src,event) obj.showStepInstructions());

            % 依据 controlFrac 摆放各面板
            obj.layoutPanels();
        end

        function layoutPanels(obj)
            %LAYOUTPANELS 根据 controlFrac 摆放控制面板、分隔条与显示区
            %   所有面板均使用归一化坐标，窗口缩放时会自动随之缩放。
            if isempty(obj.mainPanel) || ~isvalid(obj.mainPanel)
                return;
            end
            m = 0.008;            % 外边距
            splitterW = 0.009;    % 分隔条宽度
            summaryH = 0.115;     % 汇总面板高度
            cf = min(max(obj.controlFrac, 0.16), 0.55);

            set(obj.controlPanel, 'Position', ...
                [m, m, cf - m - splitterW/2, 1 - 2*m]);
            set(obj.splitter, 'Position', ...
                [cf - splitterW/2, m, splitterW, 1 - 2*m]);

            dLeft = cf + splitterW/2 + m;
            dWidth = 1 - dLeft - m;
            dBottom = m + summaryH + m;
            set(obj.summaryPanel, 'Position', ...
                [dLeft, m, dWidth, summaryH]);
            set(obj.displayPanel, 'Position', ...
                [dLeft, dBottom, dWidth, 1 - dBottom - m]);
        end

        function onFigureResize(obj)
            %ONFIGURERESIZE 窗口缩放回调：保证最小尺寸并重排面板
            if isempty(obj.fig) || ~isvalid(obj.fig)
                return;
            end
            pos = get(obj.fig, 'Position');
            minW = 980;
            minH = 640;
            newW = max(pos(3), minW);
            newH = max(pos(4), minH);
            if newW ~= pos(3) || newH ~= pos(4)
                set(obj.fig, 'Position', [pos(1), pos(2), newW, newH]);
            end
            obj.layoutPanels();
        end

        function startSplitDrag(obj)
            %STARTSPLITDRAG 开始拖动分隔条
            obj.isDraggingSplitter = true;
            set(obj.fig, 'Pointer', 'left');
            set(obj.fig, 'WindowButtonMotionFcn', @(~, ~) obj.dragSplitter());
            set(obj.fig, 'WindowButtonUpFcn', @(~, ~) obj.stopSplitDrag());
        end

        function dragSplitter(obj)
            %DRAGSPLITTER 拖动分隔条：按鼠标位置更新控制面板宽度比例
            if ~obj.isDraggingSplitter || isempty(obj.fig) || ~isvalid(obj.fig)
                return;
            end
            cp = get(obj.fig, 'CurrentPoint');
            figPos = get(obj.fig, 'Position');
            if figPos(3) <= 0
                return;
            end
            obj.controlFrac = min(max(cp(1) / figPos(3), 0.16), 0.55);
            obj.layoutPanels();
        end

        function stopSplitDrag(obj)
            %STOPSPLITDRAG 结束拖动
            obj.isDraggingSplitter = false;
            if ~isempty(obj.fig) && isvalid(obj.fig)
                set(obj.fig, 'Pointer', 'arrow');
                set(obj.fig, 'WindowButtonMotionFcn', '');
                set(obj.fig, 'WindowButtonUpFcn', '');
            end
        end

        function enableAxesToolbars(obj)
            %ENABLEAXESTOOLBARS 为显示区内每个子图启用坐标轴工具栏
            %   默认打开，便于学生用其中的"导出"按钮把单个子图保存为图片。
            if isempty(obj.displayPanel) || ~isvalid(obj.displayPanel)
                return;
            end
            axList = findall(obj.displayPanel, 'Type', 'axes');
            for k = 1:numel(axList)
                try
                    tb = axtoolbar(axList(k), ...
                        {'export', 'datacursor', 'pan', 'zoomin', ...
                         'zoomout', 'restoreview'});
                    tb.Visible = 'on';
                catch
                    % 某些辅助坐标轴不支持工具栏，忽略即可
                end
            end
        end

        function pos = subplotPos(~, nR, nC, idx, topPad, bottomPad, vGap)
            %SUBPLOTPOS 计算带充足标签间距的网格子图位置（归一化坐标）
            %   比 subplot 默认间距更大，避免上一行 xlabel 与下一行标题重叠。
            if nargin < 5 || isempty(topPad),    topPad = 0.095;    end
            if nargin < 6 || isempty(bottomPad), bottomPad = 0.055; end
            if nargin < 7 || isempty(vGap),      vGap = 0.095;      end
            leftPad = 0.075; rightPad = 0.035;
            hGap = 0.075;
            tileW = (1 - leftPad - rightPad - (nC-1)*hGap) / nC;
            tileH = (1 - topPad - bottomPad - (nR-1)*vGap) / nR;
            r = floor((idx-1)/nC) + 1;
            c = mod(idx-1, nC) + 1;
            x = leftPad + (c-1)*(tileW + hGap);
            y = 1 - topPad - r*tileH - (r-1)*vGap;
            pos = [x, y, tileW, tileH];
        end

        function reserveBottomBand(obj, bandH, topBand)
            %RESERVEBOTTOMBAND 把显示区内所有子图整体缩到上方，底部留出按钮带
            %   同时顶部留出标题带，避免子图标题与 sgtitle 重叠。
            if nargin < 2 || isempty(bandH)
                bandH = 0.11;
            end
            if nargin < 3 || isempty(topBand)
                topBand = 0.055;
            end
            if isempty(obj.displayPanel) || ~isvalid(obj.displayPanel)
                return;
            end
            axs = findall(obj.displayPanel, 'Type', 'axes');
            for k = 1:numel(axs)
                set(axs(k), 'Units', 'normalized');
                p = get(axs(k), 'Position');
                if numel(p) < 4
                    continue;
                end
                scale = 1 - bandH - topBand;
                newH = p(4) * scale;
                newB = bandH + p(2) * scale;
                set(axs(k), 'Position', [p(1), newB, p(3), newH]);
            end
        end

        function initializeData(obj)
            %INITIALIZEDATA 初始化示例信号数据
            %   生成用于演示的标准信号：正弦波、余弦波、方波、锯齿波。
            obj.t = linspace(0, 4*pi, 1000);
            obj.f = linspace(0, 10, 1000);

            % 生成一些示例信号
            obj.signals.sine = sin(obj.t);
            obj.signals.cos = cos(obj.t);
            obj.signals.square = square(obj.t);
            obj.signals.sawtooth = sawtooth(obj.t);
        end

        % === 从CSV文件加载所有显示文本 ===
        function loadDisplayTexts(obj)
            %LOADDISPLAYTEXTS 从 display_texts.csv 加载所有显示文本
            %   使用自定义解析器按引号边界分割逗号，兼容部分字段未加引号的CSV。
            %   CSV 列：1=步骤编号  2=标题  3=操作说明  4=详细讲解  5=汇总文本
            %   LG 行的学习指南文本位于列3（操作说明列）。
            %   文本中的 \n 会被替换为 MATLAB 换行符 newline。

            csvPath = fullfile(fileparts(mfilename('fullpath')), 'display_texts.csv');

            if ~isfile(csvPath)
                warning('FourierTransformExplainer:CSVMissing', ...
                    '找不到文本文件，使用内置默认文本。');
                obj.useBuiltinTexts();
                return;
            end

            try
                data = readCSV(obj, csvPath);  % 自定义解析器，返回 cell 数组
                % data: N行 × 5列，第1行为表头

                % 分离步骤行（列1为数字）和 LG 行
                col1 = data(2:end, 1);
                isStep = ~strcmp(col1, 'LG');
                isLG   =  strcmp(col1, 'LG');

                stepData = data(find(isStep) + 1, :);  % +1 补偿表头偏移
                nSteps = size(stepData, 1);

                obj.stepTitles            = cell(nSteps, 1);  % 列2→按钮
                obj.explanationContents   = cell(nSteps, 1);  % 列3→操作说明（控制面板）
                obj.operationInstructions = cell(nSteps, 1);  % 列4→详细讲解（步骤说明按钮）
                obj.summaryContents       = cell(nSteps, 1);  % 列5→汇总（底部面板）

                for i = 1:nSteps
                    obj.stepTitles{i}            = stepData{i, 2};
                    obj.explanationContents{i}   = strrep(stepData{i, 3}, '\n', newline);
                    obj.operationInstructions{i} = strrep(stepData{i, 4}, '\n', newline);
                    obj.summaryContents{i}       = strrep(stepData{i, 5}, '\n', newline);
                end

                % 学习指南（LG行列3）
                if any(isLG)
                    lgData = data(find(isLG) + 1, :);
                    obj.learningGuideContent = strrep(lgData{1, 3}, '\n', newline);
                else
                    obj.learningGuideContent = '学习指南内容未找到。';
                end
            catch ME
                warning('FourierTransformExplainer:CSVReadError', ...
                    '读取CSV失败 (%s)，使用内置默认文本。', ME.message);
                obj.useBuiltinTexts();
            end
        end

        function data = readCSV(~, filePath)
            %READCSV 按引号边界分割CSV行，兼容部分字段未加引号的情况
            %   返回 N行×M列 的 cell 数组，第1行为表头。
            fid = fopen(filePath, 'r', 'n', 'UTF-8');
            raw = fread(fid, '*char')';
            fclose(fid);

            % 去除 UTF-8 BOM（对比字节值而非 Unicode 码点）
            if numel(raw) >= 3 && uint8(raw(1))==239 && uint8(raw(2))==187 && uint8(raw(3))==191
                raw = raw(4:end);
            end

            % 按实际换行符分割（splitlines 自动处理 \r\n \n \r）
            lines = splitlines(raw);
            lines = lines(~cellfun(@(s) isempty(strtrim(s)), lines));

            data = cell(length(lines), 5);
            data(:) = {''};
            nRows = 0;

            for li = 1:length(lines)
                line = strtrim(lines{li});
                if isempty(line), continue; end
                nRows = nRows + 1;
                fields = splitQuoted(line, ',');
                for fi = 1:min(numel(fields), 5)
                    data{nRows, fi} = fields{fi};
                end
            end
            data = data(1:nRows, :);
        end

        function useBuiltinTexts(obj)
            %USEBUILTINTEXTS CSV 文件不可用时的后备文本（精简版）
            obj.stepTitles = {
                '时域与频域的基本概念';
                '傅里叶级数：正弦波叠加逼近方波';
                '谐波叠加的收敛过程';
                '相位谱：频谱的另一半';
                '欧拉公式：复数与三角函数的桥梁';
                '傅里叶级数与傅里叶变换的对比';
                '指数形式的傅里叶变换：正向与反向';
                '采样定理——完全采样与混叠';
                'NMR脉冲调制：傅里叶变换的实际应用';
                'NMR自由感应衰减（FID）信号';
                '总结：傅里叶变换的意义与启示'
            };
            obj.summaryContents = cell(11, 1);
            obj.explanationContents = cell(11, 1);
            obj.operationInstructions = cell(11, 1);
            obj.learningGuideContent = '学习指南内容未加载。请检查 display_texts.csv 文件。';
            for i = 1:11
                obj.explanationContents{i}   = sprintf('步骤%d\n\n操作说明未能从CSV文件加载。', i);
                obj.operationInstructions{i} = sprintf('步骤%d\n\n详细讲解未能从CSV文件加载。', i);
                obj.summaryContents{i}       = sprintf('步骤%d\n\n汇总文本未能从CSV文件加载。', i);
            end
        end

        function updateSummaryText(obj, stepNum)
            %UPDATESUMMARYTEXT 更新汇总文本框内容
            %   updateSummaryText(obj, stepNum) 将汇总面板文本切换为指定步骤的要点。
            if stepNum >= 1 && stepNum <= length(obj.summaryContents)
                set(obj.summaryText, 'String', obj.summaryContents{stepNum});
                try
                    set(obj.summaryText, 'ListboxTop', 1);
                catch ME
                    warning('FourierTransformExplainer:ListboxTop', ...
                        '无法重置滚动位置: %s', ME.message);
                end
            else
                set(obj.summaryText, 'String', '步骤编号无效。');
            end
        end

        % 选择特定步骤
        function selectStep(obj, stepNum)
            %SELECTSTEP 跳转到指定讲解步骤
            %   selectStep(obj, stepNum) 将显示切换到第 stepNum 步。
            obj.currentStep = stepNum;
            obj.updateDisplay();
        end

        function updateDisplay(obj)
            %UPDATEDISPLAY 更新显示面板内容
            %   根据 currentStep 调用对应的展示方法，并更新解释文本和汇总面板。

            % 清除显示面板中的所有旧内容（axes + 步骤专用 UIControls）
            delete(obj.displayPanel.Children);

            % 清除旧的 sgtitle（它是 figure 的子对象，不在 displayPanel 中）
            delete(findall(obj.fig, 'Tag', 'sgtitle'));

            switch obj.currentStep
                case 1
                    obj.showTimeFrequencyDomain();
                case 2
                    obj.showFourierSeriesSpectrum();
                case 3
                    obj.showSquareWaveApproximation();
                case 4
                    obj.showPhaseSpectrum();
                case 5
                    obj.showEulerFormula();
                case 6
                    obj.showFourierTransformPrinciple();
                case 7
                    obj.showExponentialForm();
                case 8
                    obj.showSamplingTheorem();
                case 9
                    obj.showNMRPulseTransition();
                case 10
                    obj.showFID();
                case 11
                    obj.showSummary();
            end

            % 更新解释文本和汇总文本
            obj.updateExplanationText();
            obj.updateSummaryText(obj.currentStep);

            % 为各子图启用坐标轴工具栏（含"导出"按钮）
            obj.enableAxesToolbars();
        end

        % 步骤1：时域与频域概念
        function showTimeFrequencyDomain(obj)
            %SHOWTIMEFREQUENCYDOMAIN 步骤1——时域与频域概念对比
            %   通过4个子图展示：时域正弦波、频域单一频率、时域复杂波形、频域频谱。
            subplot(2, 2, 1, 'Parent', obj.displayPanel);
            plot(obj.t, sin(2*pi*obj.t), 'b', 'LineWidth', 2);
            title('时域：正弦波随时间变化', 'FontSize', 12);
            xlabel('时间 (s)');
            ylabel('振幅');
            xlim([0, 5]);
            ylim([-1.5,1.5]);
            grid on;

            subplot(2, 2, 2, 'Parent', obj.displayPanel);
            stem([1], [1], 'r', 'LineWidth', 2, 'MarkerSize', 10);
            title('频域：单一频率成分', 'FontSize', 12);
            xlabel('频率 (Hz)');
            ylabel('振幅');
            xlim([0, 2]);
            ylim([-0.1,1.2]);
            grid on;

            subplot(2, 2, 3, 'Parent', obj.displayPanel);
            t_music = linspace(0, 0.2, 1000);
            music_signal = sin(2*pi*440*t_music) + 0.5*sin(2*pi*880*t_music) + 0.8*sin(2*pi*1320*t_music);
            plot(t_music, music_signal, 'g', 'LineWidth', 2);
            title('时域：复杂波形', 'FontSize', 12);
            xlabel('时间 (s)');
            ylabel('振幅');
            xlim([0, 0.02]);
            ylim([-2.0,2.0]);
            grid on;

            subplot(2, 2, 4, 'Parent', obj.displayPanel);
            frequencies = [440/1000, 880/1000, 1320/1000];
            amplitudes = [1, 0.5, 0.8];
            stem(frequencies, amplitudes, 'm', 'LineWidth', 2, 'MarkerSize', 10);
            title('频域：复杂波形频谱', 'FontSize', 12);
            xlabel('频率 (kHz)');
            ylabel('振幅');
            xlim([0, 1.5]);
            ylim([-0.1,1.2]);
            grid on;

            sgtitle('步骤1：时域与频域的概念对比', 'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤2：傅里叶级数频谱
        function showFourierSeriesSpectrum(obj)
            %SHOWFOURIERSERIESSPECTRUM 步骤2——傅里叶级数频谱
            %   展示标准方波的傅里叶分解：4个子图分别展示基波、叠加过程、3D视图和频谱。
            t = linspace(-pi/2, 7*pi/2, 1000);

            square_wave_ref = sign(sin(t));

            % 第一部分：基波
            ax1 = subplot(2, 3, 1, 'Parent', obj.displayPanel);
            fundamental = (4/pi) * sin(t);

            plot(ax1, t, fundamental, 'b', 'LineWidth', 2);
            hold(ax1, 'on');
            plot(ax1, t, fundamental, 'k', 'LineWidth', 3);
            plot(ax1, t, square_wave_ref, 'r--', 'LineWidth', 1.5);
            hold(ax1, 'off');

            title(ax1, '1. 基波: (4/π)sin(t)', 'FontSize', 10);
            xlabel(ax1, '时间 (弧度)');
            ylabel(ax1, '振幅');
            legend(ax1, {'基波', '叠加总和', '标准方波'}, ...
                'Location', 'southeast', 'FontSize', 8);
            grid(ax1, 'on');

            xlim(ax1, [-0.5*pi, 3.5*pi]);
            xticks([-0.5*pi, 0, 0.5*pi, pi, 1.5*pi, 2*pi, 2.5*pi, 3*pi, 3.5*pi]);
            xticklabels({'-0.5π', '0', '0.5π', 'π', '1.5π', '2π', '2.5π', '3π', '3.5π'});
            ylim(ax1, [-1.5, 1.5]);

            % 第二部分：基波 + 3次谐波
            ax2 = subplot(2, 3, 2, 'Parent', obj.displayPanel);
            harmonic3 = (4/(3*pi)) * sin(3*t);
            sum_signal = fundamental + harmonic3;

            plot(ax2, t, fundamental, 'b', 'LineWidth', 1.5);
            hold(ax2, 'on');
            plot(ax2, t, harmonic3, 'r', 'LineWidth', 1.5);
            plot(ax2, t, sum_signal, 'k', 'LineWidth', 3);
            plot(ax2, t, square_wave_ref, 'r--', 'LineWidth', 1.5);
            hold(ax2, 'off');

            title(ax2, '2. 叠加: (4/π)[sin(t) + (1/3)sin(3t)]', 'FontSize', 10);
            xlabel(ax2, '时间 (弧度)');
            ylabel(ax2, '振幅');
            legend(ax2, {'基波', '3次谐波', '叠加总和', '标准方波'}, ...
                'Location', 'southeast', 'FontSize', 8);
            grid(ax2, 'on');

            xlim(ax2, [-0.5*pi, 3.5*pi]);
            xticks([-0.5*pi, 0, 0.5*pi, pi, 1.5*pi, 2*pi, 2.5*pi, 3*pi, 3.5*pi]);
            xticklabels({'-0.5π', '0', '0.5π', 'π', '1.5π', '2π', '2.5π', '3π', '3.5π'});
            ylim(ax2, [-1.5, 1.5]);

            % 第三部分：基波 + 3次 + 5次谐波
            ax3 = subplot(2, 3, 3, 'Parent', obj.displayPanel);
            harmonic5 = (4/(5*pi)) * sin(5*t);
            sum_signal = fundamental + harmonic3 + harmonic5;

            plot(ax3, t, fundamental, 'b', 'LineWidth', 1);
            hold(ax3, 'on');
            plot(ax3, t, harmonic3, 'r', 'LineWidth', 1);
            plot(ax3, t, harmonic5, 'g', 'LineWidth', 1);
            plot(ax3, t, sum_signal, 'k', 'LineWidth', 3);
            plot(ax3, t, square_wave_ref, 'r--', 'LineWidth', 1.5);
            hold(ax3, 'off');

            title(ax3, '3. 叠加: 前3个奇次谐波(1,3,5)', 'FontSize', 10);
            xlabel(ax3, '时间 (弧度)');
            ylabel(ax3, '振幅');
            legend(ax3, {'基波', '3次谐波', '5次谐波', '叠加总和', '标准方波'}, ...
                'Location', 'southeast', 'FontSize', 7, 'NumColumns', 2);
            grid(ax3, 'on');

            xlim(ax3, [-0.5*pi, 3.5*pi]);
            xticks([-0.5*pi, 0, 0.5*pi, pi, 1.5*pi, 2*pi, 2.5*pi, 3*pi, 3.5*pi]);
            xticklabels({'-0.5π', '0', '0.5π', 'π', '1.5π', '2π', '2.5π', '3π', '3.5π'});
            ylim(ax3, [-1.5, 1.5]);

            % 第四部分：3D视图
            ax4 = subplot(2, 3, [4, 6], 'Parent', obj.displayPanel);

            num_frequencies = 9;
            harmonics = 1:num_frequencies;

            colors = parula(num_frequencies);

            cla(ax4);
            hold(ax4, 'on');
            grid(ax4, 'on');
            view(ax4, 45, 25);

            amplitudes = zeros(1, num_frequencies);
            for n = 1:num_frequencies
                if mod(n, 2) == 1
                    amplitudes(n) = 4/(pi*n);
                else
                    amplitudes(n) = 0;
                end
            end

            waveform_x_min = -pi/2;
            spectrum_offset = pi/4;
            spectrum_x = waveform_x_min - spectrum_offset;

            for i = 1:num_frequencies
                n = harmonics(i);

                if mod(n, 2) == 1
                    harmonic = (4/(pi*n)) * sin(n*t);

                    plot3(ax4, t, ones(size(t))*i, harmonic, ...
                        'Color', colors(i,:), 'LineWidth', 1.5);

                    text(ax4, max(t)*0.9, i, max(harmonic)*1.1, ...
                        sprintf('f_%d', n), 'FontSize', 8, 'Color', colors(i,:));
                else
                    plot3(ax4, t, ones(size(t))*i, zeros(size(t)), ...
                        'Color', [0.6, 0.6, 0.6], 'LineWidth', 1, 'LineStyle', '-');

                    text(ax4, max(t)*0.9, i, 0.1, ...
                        sprintf('f_%d=0', n), 'FontSize', 8, 'Color', [0.6, 0.6, 0.6]);
                end
            end

            final_sum = zeros(size(t));
            for n = 1:2:9
                final_sum = final_sum + (4/(pi*n)) * sin(n*t);
            end
            plot3(ax4, t, ones(size(t))*num_frequencies, final_sum, ...
                'Color', 'k', 'LineWidth', 3);

            square_wave = square(t);
            plot3(ax4, t, ones(size(t))*(num_frequencies+0.5), square_wave, ...
                'Color', 'r', 'LineWidth', 2, 'LineStyle', ':');

            plot3(ax4, [spectrum_x+0.05, spectrum_x+0.05], [0.5, num_frequencies+0.5], [-1.5, 1.5], ...
                'k:', 'LineWidth', 1);

            spectrum_base_z = -1;

            for n = 1:num_frequencies
                if mod(n, 2) == 1
                    spectrum_height = amplitudes(n);
                    z_start = spectrum_base_z;
                    z_end = spectrum_base_z + spectrum_height;

                    plot3(ax4, [spectrum_x, spectrum_x], [n, n], [z_start, z_end], ...
                        'Color', colors(n,:), 'LineWidth', 2, 'LineStyle', '-');

                    plot3(ax4, spectrum_x, n, z_end, 'o', ...
                        'MarkerSize', 6, 'MarkerFaceColor', colors(n,:), 'MarkerEdgeColor', 'k');

                    text(ax4, spectrum_x-0.1, n, z_end+0.2, ...
                        sprintf('%.3f', amplitudes(n)), 'FontSize', 7, 'Color', 'k');
                else
                    plot3(ax4, spectrum_x, n, spectrum_base_z, 'o', ...
                        'MarkerSize', 4, 'MarkerFaceColor', [0.7, 0.7, 0.7], 'MarkerEdgeColor', 'none');

                    text(ax4, spectrum_x-0.1, n, spectrum_base_z, ...
                        '0', 'FontSize', 7, 'Color', [0.5, 0.5, 0.5]);
                end
            end

            [Y, Z] = meshgrid(0.5:num_frequencies+0.5, -1.5:0.1:1.5);
            X = spectrum_x * ones(size(Y));
            surf(ax4, X, Y, Z, 'FaceColor', [0.95, 0.95, 0.95], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            [Y_baseline, X_baseline] = meshgrid(0.5:num_frequencies+0.5, spectrum_x-0.05:0.01:spectrum_x+0.05);
            Z_baseline = spectrum_base_z * ones(size(X_baseline));
            surf(ax4, X_baseline, Y_baseline, Z_baseline, 'FaceColor', 'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

            xlabel(ax4, '时间（弧度）');
            ylabel(ax4, '谐波阶数(n)');
            zlabel(ax4, '振幅');
            title(ax4, '标准方波的傅里叶分解（3D视图）', 'FontSize', 10);

            xlim(ax4, [spectrum_x - 0.1, 3*pi/2]);
            xticks(ax4, [spectrum_x, -pi/2, 0, pi/2, pi, 3*pi/2]);
            xticklabels(ax4, {'频谱图', '-π/2', '0', 'π/2', 'π', '3π/2'});
            ylim(ax4, [0.5, num_frequencies+1]);
            zlim(ax4, [-1.5, 1.5]);

            legend_handles = [
                plot3(ax4, NaN, NaN, NaN, 'b-', 'LineWidth', 2);
                plot3(ax4, NaN, NaN, NaN, 'k--', 'LineWidth', 1.5);
                plot3(ax4, NaN, NaN, NaN, 'k-', 'LineWidth', 3);
                plot3(ax4, NaN, NaN, NaN, 'r:', 'LineWidth', 2);
                plot3(ax4, NaN, NaN, NaN, 'Color', [0.6,0.6,0.6], 'LineWidth', 1);
                plot3(ax4, NaN, NaN, NaN, 'b-', 'LineWidth', 4);
            ];

            legend_labels = {
                '各谐波分量',
                '到当前频率的叠加',
                '最终叠加结果 (9次谐波)',
                '理想矩形波',
                '偶次谐波 (振幅=0)',
                '频谱图 (奇次谐波)'
            };

            legend(ax4, legend_handles, legend_labels, ...
                'Location', 'northeast', 'FontSize', 8, 'NumColumns', 2);

            hold(ax4, 'off');

            ylim(ax1, [-2.2, 1.6]);   % 底部留白，避免图例盖住波形
            ylim(ax2, [-2.4, 1.6]);
            ylim(ax3, [-2.4, 1.6]);

            sgtitle('步骤2：傅里叶级数 - 正弦波叠加逼近矩形波', 'FontSize', 14, 'FontWeight', 'bold');

            % 添加动画演示按钮（底部预留按钮带，避免按钮盖住子图）
            obj.reserveBottomBand(0.11);
            uicontrol('Parent', obj.displayPanel, ...
                'Style', 'pushbutton', ...
                'String', '级数分解动画', ...
                'Units', 'normalized', ...
                'Position', [0.31, 0.02, 0.17, 0.07], ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.8, 0.9, 1], ...
                'Callback', @(src,event) obj.launchFourierSeriesAnimation());

            uicontrol('Parent', obj.displayPanel, ...
                'Style', 'pushbutton', ...
                'String', '旋转圆动画', ...
                'Units', 'normalized', ...
                'Position', [0.52, 0.02, 0.17, 0.07], ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.8, 1, 0.8], ...
                'Callback', @(src,event) obj.launchEulerAnimation());
        end

        % 步骤3：正弦波叠加成矩形波
        function showSquareWaveApproximation(obj)
            %SHOWSQUAREWAVEAPPROXIMATION 步骤3——谐波叠加逼近矩形波
            %   以6个子图展示 1/3/5/7/15/50 个谐波对理想矩形波的逼近效果。
            t = linspace(-pi/2, 7*pi/2, 2000);

            square_wave = square(t);

            harmonics = [1, 3, 5, 7, 15, 50];

            for i = 1:6
                ax = subplot(2, 3, i, 'Parent', obj.displayPanel);

                N = harmonics(i);
                approx_signal = zeros(size(t));
                for n = 1:2:N
                    approx_signal = approx_signal + sin(n*t)/n;
                end

                approx_signal = (4/pi) * approx_signal;

                center_idx = find(t >= -0.5*pi & t <= 3.5*pi);
                t_center = t(center_idx);
                approx_center = approx_signal(center_idx);
                square_center = square_wave(center_idx);

                plot(ax, t_center, approx_center, 'b', 'LineWidth', 2);
                hold(ax, 'on');
                plot(ax, t_center, square_center, 'r--', 'LineWidth', 1);
                hold(ax, 'off');

                title(ax, [num2str(N), '个谐波叠加'], 'FontSize', 10);
                xlabel(ax, '时间');
                ylabel(ax, '振幅');
                legend(ax, '近似波形', '理想矩形波', ...
                    'Location', 'southeast', 'FontSize', 8);
                grid(ax, 'on');

                xlim(ax, [-0.5*pi, 3.5*pi]);
                ylim(ax, [-2.0, 1.6]);   % 底部留白，避免图例盖住波形
                xticks([-0.5*pi, 0, 0.5*pi, pi, 1.5*pi, 2*pi, 2.5*pi, 3*pi, 3.5*pi]);
                xticklabels({'-0.5π', '0', '0.5π', 'π', '1.5π', '2π', '2.5π','3π', '3.5π'});
            end

            sgtitle('步骤3：不同数量谐波对矩形波的逼近效果（两个周期）', 'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤4：相位谱的概念
        function showPhaseSpectrum(obj)
            %SHOWPHASESPECTRUM 步骤4——相位谱概念
            %   8个子图展示：相位差影响、正弦/余弦展开的振幅谱与相位谱、时域合成对比。

            % 4行×2列布局（共8个子图）。使用自定义间距，避免上下行文字重叠。
            % 第1-2行：相位基本概念与正弦展开
            % 第3-4行：余弦展开与时域合成对比

            % 子图1：相位差对单个正弦波的影响
            ax1 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 1));
            t = linspace(0, 2*pi, 500);

            % 创建三个不同相位的正弦波
            plot(ax1, t, sin(t), 'b-', 'LineWidth', 2);
            hold(ax1, 'on');
            plot(ax1, t, sin(t + pi/2), 'r--', 'LineWidth', 2);
            plot(ax1, t, sin(t + pi), 'g:', 'LineWidth', 2);
            hold(ax1, 'off');

            title(ax1, '1. 相位差的影响', 'FontSize', 9);
            xlabel(ax1, '时间 (弧度)');
            ylabel(ax1, '振幅');
            legend(ax1, {'相位0 (sinθ)', '相位π/2', '相位π'}, ...
                   'Location', 'southeast', 'FontSize', 7);
            grid(ax1, 'on');
            xlim(ax1, [0, 2*pi]);
            ylim(ax1, [-2.0, 1.6]);   % 底部留白，避免图例盖住曲线
            xticks([0, pi/2, pi, 3*pi/2, 2*pi]);
            xticklabels({'0', 'π/2', 'π', '3π/2', '2π'});

            % 子图2：相同频率成分，不同相位组合产生不同波形
            ax2 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 2));

            t2 = linspace(0, 2*pi, 500);

            % 信号A：基波+3次谐波，特定相位
            sigA = 1.0*sin(1*t2 + 0) + 0.5*sin(3*t2 + pi/4);

            % 信号B：相同频率成分，不同相位
            sigB = 1.0*sin(1*t2 + pi/2) + 0.5*sin(3*t2 + 0);

            plot(ax2, t2, sigA, 'b-', 'LineWidth', 2);
            hold(ax2, 'on');
            plot(ax2, t2, sigB, 'r--', 'LineWidth', 2);
            hold(ax2, 'off');

            title(ax2, '2. 相同振幅+不同相位=不同波形', 'FontSize', 9);
            xlabel(ax2, '时间 (弧度)');
            ylabel(ax2, '振幅');
            legend(ax2, {'相位组合A', '相位组合B'}, ...
                'Location', 'southwest', 'FontSize', 7);
            grid(ax2, 'on');
            xlim(ax2, [0, 2*pi]);
            ylim(ax2, [-2.0, 1.6]);   % 底部留白，避免图例盖住曲线
            xticks([0, pi/2, pi, 3*pi/2, 2*pi]);
            xticklabels({'0', 'π/2', 'π', '3π/2', '2π'});

            % 子图3：方波正弦展开的振幅谱（偶谐波用灰色点标记）
            ax3 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 3));

            n_all = 1:9;  % 所有谐波（1到9次）
            % 计算所有谐波的振幅
            bn_all = zeros(size(n_all));
            for i = 1:length(n_all)
                n = n_all(i);
                if mod(n, 2) == 1  % 奇次谐波
                    bn_all(i) = 4/(pi*n);
                else  % 偶次谐波，振幅为0
                    bn_all(i) = 0;
                end
            end

            % 分离奇偶谐波
            odd_idx = mod(n_all, 2) == 1;
            even_idx = mod(n_all, 2) == 0;

            % 绘制奇次谐波（蓝色杆状图）
            if any(odd_idx)
                stem(ax3, n_all(odd_idx), bn_all(odd_idx), 'b', 'LineWidth', 1.5, ...
                     'MarkerSize', 6, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                hold(ax3, 'on');
            end

            % 绘制偶次谐波（灰色圆点，标记为0）
            if any(even_idx)
                % 在偶次谐波位置绘制灰色圆点
                plot(ax3, n_all(even_idx), bn_all(even_idx), 'o', ...
                     'MarkerSize', 6, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                     'MarkerEdgeColor', [0.5, 0.5, 0.5], 'LineWidth', 1);
            end

            title(ax3, '3. 正弦展开振幅谱 b_n', 'FontSize', 9);
            xlabel(ax3, '谐波阶数 n');
            ylabel(ax3, '振幅 b_n');
            grid(ax3, 'on');
            xlim(ax3, [0.5, 9.5]);
            ylim(ax3, [-0.1, max(bn_all)*1.2]);

            % 添加公式
            text(ax3, 2, max(bn_all)*0.8, 'b_n = 4/(πn), n=1,3,5...', ...
                 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'b');

            % 添加图例
            if any(odd_idx) && any(even_idx)
                legend(ax3, {'奇次谐波', '偶次谐波 (0)'}, 'Location', 'northeast', 'FontSize', 6);
            end

            hold(ax3, 'off');

            % 子图4：方波余弦展开的振幅谱（显示绝对值，颜色区分正负）
            ax4 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 4));

            % 计算偶对称方波的傅里叶系数 an
            % an = (4/(πn)) sin(nπ/2)

            n_cos = 1:9;
            an = zeros(size(n_cos));

            for i = 1:length(n_cos)
                n = n_cos(i);
                an(i) = (4/(pi*n)) * sin(n*pi/2);
            end

            % 计算振幅（绝对值）
            abs_an = abs(an);

            % 分离奇偶谐波
            odd_cos_idx = mod(n_cos, 2) == 1;
            even_cos_idx = mod(n_cos, 2) == 0;

            % 绘制奇次谐波（区分正负系数）
            for n = n_cos(odd_cos_idx)
                i = find(n_cos == n);
                if an(i) > 0
                    % 正系数（蓝色）
                    stem(ax4, n, abs_an(i), 'b', 'LineWidth', 1.5, ...
                         'MarkerSize', 6, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                else
                    % 负系数（红色）
                    stem(ax4, n, abs_an(i), 'r', 'LineWidth', 1.5, ...
                         'MarkerSize', 6, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
                end
                hold(ax4, 'on');
            end

            % 绘制偶次谐波（灰色圆点）
            if any(even_cos_idx)
                plot(ax4, n_cos(even_cos_idx), zeros(1, sum(even_cos_idx)), 'o', ...
                     'MarkerSize', 6, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                     'MarkerEdgeColor', [0.5, 0.5, 0.5], 'LineWidth', 1);
            end

            title(ax4, '4. 余弦展开振幅谱 |a_n|', 'FontSize', 9);
            xlabel(ax4, '谐波阶数 n');
            ylabel(ax4, '振幅 |a_n|');
            grid(ax4, 'on');
            xlim(ax4, [0.5, 9.5]);
            ylim(ax4, [-0.05, max(abs_an)*1.2]);  % 调整y轴下限

            % 添加公式
            text(ax4, 2, max(abs_an)*0.8, 'a_n = (4/πn) sin(nπ/2)', ...
                 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'b');

            % 添加图例
            legend_handles = [];
            legend_labels = {};

            % 创建图例句柄
            if any(an(odd_cos_idx) > 0)
                legend_handles(end+1) = plot(ax4, NaN, NaN, 'b-', 'LineWidth', 1.5);
                legend_labels{end+1} = '正系数 (an>0)';
            end

            if any(an(odd_cos_idx) < 0)
                legend_handles(end+1) = plot(ax4, NaN, NaN, 'r-', 'LineWidth', 1.5);
                legend_labels{end+1} = '负系数 (an<0)';
            end

            if any(even_cos_idx)
                legend_handles(end+1) = plot(ax4, NaN, NaN, 'o', ...
                    'MarkerSize', 6, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                    'MarkerEdgeColor', [0.5, 0.5, 0.5]);
                legend_labels{end+1} = '偶次谐波 (0)';
            end

            if ~isempty(legend_handles)
                legend(ax4, legend_handles, legend_labels, 'Location', 'northeast', 'FontSize', 6);
            end

            hold(ax4, 'off');

            % 子图5：方波正弦展开的相位谱
            ax5 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 5));

            % 方波正弦展开：所有系数为正，相位为0
            phases_bn = zeros(size(n_all(odd_idx)));  % 所有相位为0

            stem(ax5, n_all(odd_idx), phases_bn, 'r', 'LineWidth', 1.5, ...
                 'MarkerSize', 6, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');

            title(ax5, '5. 正弦展开相位谱', 'FontSize', 9);
            xlabel(ax5, '谐波阶数 n');
            ylabel(ax5, '相位 φ_n (弧度)');
            grid(ax5, 'on');
            xlim(ax5, [0.5, 9.5]);
            ylim(ax5, [-0.5, pi+0.5]);
            yticks([0, pi/2, pi]);
            yticklabels({'0', 'π/2', 'π'});

            % 标注
            text(ax5, 5, pi*0.8, '所有 φ_n = 0', ...
                 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'r');

            % 子图6：方波余弦展开的相位谱
            ax6 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 6));

            % 只绘制非零系数的相位
            non_zero_idx = abs(an) > 1e-10;
            n_non_zero = n_cos(non_zero_idx);
            phases_an = zeros(size(n_non_zero));

            % 确定相位：正系数→相位0，负系数→相位π
            for i = 1:length(n_non_zero)
                if an(non_zero_idx(i)) > 0
                    phases_an(i) = 0;
                else
                    phases_an(i) = pi;
                end
            end

            % 绘制相位谱
            stem(ax6, n_non_zero, phases_an, 'm', 'LineWidth', 1.5, ...
                 'MarkerSize', 6, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');

            title(ax6, '6. 余弦展开相位谱', 'FontSize', 9);
            xlabel(ax6, '谐波阶数 n');
            ylabel(ax6, '相位 φ_n (弧度)');
            grid(ax6, 'on');
            xlim(ax6, [0.5, 9.5]);
            ylim(ax6, [-0.5, pi+0.5]);
            yticks([0, pi/2, pi]);
            yticklabels({'0', 'π/2', 'π'});

            % 标记相位值
            for i = 1:length(n_non_zero)
                if phases_an(i) == 0
                    text(ax6, n_non_zero(i), 0.5, '0', ...
                         'FontSize', 7, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                else
                    text(ax6, n_non_zero(i)+0.3, pi+0.2, 'π', ...
                         'FontSize', 7, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                end
            end

            % 子图7：方波正弦展开的时域合成
            ax7 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 7));

            t_synth = linspace(-pi/2, 7*pi/2, 1000);

            % 用前5个奇次谐波合成方波
            N_harmonics = 5;
            synth_signal = zeros(size(t_synth));

            for n = 1:2:2*N_harmonics-1
                synth_signal = synth_signal + (4/(pi*n)) * sin(n*t_synth);
            end

            % 绘制合成信号
            plot(ax7, t_synth, synth_signal, 'b-', 'LineWidth', 2);
            hold(ax7, 'on');

            % 绘制理想方波
            square_wave = sign(sin(t_synth));
            plot(ax7, t_synth, square_wave, 'r--', 'LineWidth', 1);

            title(ax7, '7. 正弦展开合成', 'FontSize', 9);
            xlabel(ax7, '时间 (弧度)');
            ylabel(ax7, '振幅');
            legend(ax7, {'正弦展开合成', '理想方波'}, ...
                'Location', 'south', 'FontSize', 7);
            grid(ax7, 'on');
            xlim(ax7, [-pi/2, 3*pi/2]);
            ylim(ax7, [-2.0, 1.6]);   % 底部留白，避免图例盖住波形

            % 设置π形式的横坐标
            xticks([-pi/2, 0, pi/2, pi, 3*pi/2]);
            xticklabels({'-\pi/2', '0', '\pi/2', '\pi', '3\pi/2'});
            hold(ax7, 'off');

            % 子图8：方波余弦展开的时域合成
            ax8 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(4, 2, 8));

            % 用余弦展开合成方波（偶对称方波）
            t_even = linspace(-pi, pi, 1000);
            even_square = sign(cos(t_even));

            % 用前5个非零余弦项合成
            synth_even = zeros(size(t_even));

            for n = 1:2:9
                % 计算an系数
                an_val = (4/(pi*n)) * sin(n*pi/2);
                % 添加余弦项
                synth_even = synth_even + an_val * cos(n*t_even);
            end

            plot(ax8, t_even, synth_even, 'b-', 'LineWidth', 2);
            hold(ax8, 'on');
            plot(ax8, t_even, even_square, 'r--', 'LineWidth', 1);

            title(ax8, '8. 余弦展开合成', 'FontSize', 9);
            xlabel(ax8, '时间 (弧度)');
            ylabel(ax8, '振幅');
            legend(ax8, {'余弦展开合成', '偶对称方波'}, ...
                'Location', 'south', 'FontSize', 7);
            grid(ax8, 'on');
            xlim(ax8, [-pi, pi]);
            ylim(ax8, [-2.0, 1.6]);   % 底部留白，避免图例盖住波形

            % 设置π形式的横坐标
            xticks([-pi, -pi/2, 0, pi/2, pi]);
            xticklabels({'-\pi', '-\pi/2', '0', '\pi/2', '\pi'});
            hold(ax8, 'off');

            sgtitle('步骤4：相位谱的概念 - 完整频谱 = 振幅谱 + 相位谱', 'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤5：欧拉公式与复平面
        function showEulerFormula(obj)
            %SHOWEULERFORMULA 步骤5——欧拉公式与复平面
            %   左侧：复平面上正负频率向量及sin/cos投影。右侧：3D螺旋线 e^{iθ} 及其投影。

            % 子图1：复平面显示
            ax_main = subplot(1, 2, 1, 'Parent', obj.displayPanel);

            % 定义复平面参数
            theta = linspace(0, 2*pi, 100);
            unit_circle_x = cos(theta);
            unit_circle_y = sin(theta);

            % 绘制单位圆
            plot(ax_main, unit_circle_x, unit_circle_y, 'b-', 'LineWidth', 1.5);
            hold(ax_main, 'on');

            % 绘制坐标轴
            plot(ax_main, [-1.2, 1.2], [0, 0], 'k-', 'LineWidth', 1);
            plot(ax_main, [0, 0], [-1.2, 1.2], 'k-', 'LineWidth', 1);

            % 定义关键相位角
            key_angles_deg = [0, 30, 45, 60, 90, 120, 135, 180];
            key_angles = deg2rad(key_angles_deg);

            % 创建配色方案
            colors = jet(length(key_angles));

            % 绘制正频率关键相位的向量（实线）
            for i = 1:length(key_angles)
                angle = key_angles(i);
                x = cos(angle);
                y = sin(angle);

                % 绘制向量
                quiver(ax_main, 0, 0, x, y, 'Color', colors(i,:), ...
                    'LineWidth', 1.5, 'MaxHeadSize', 0.3);

                % 标注相位角
                if key_angles_deg(i) == 0
                    text(ax_main, x*1.15, y*1.15, sprintf('0°'), ...
                        'FontSize', 7, 'Color', colors(i,:));
                else
                    text(ax_main, x*1.15, y*1.15, sprintf('+%d°', key_angles_deg(i)), ...
                        'FontSize', 7, 'Color', colors(i,:));
                end

                % 在单位圆上标记关键点
                plot(ax_main, x, y, 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');
            end

            % 绘制负频率关键相位的向量（虚线，使用相同颜色）
            for i = 1:length(key_angles)
                % 负角度（对称）
                angle_neg = -key_angles(i);
                x_neg = cos(angle_neg);
                y_neg = sin(angle_neg);

                % 绘制向量（虚线）
                quiver(ax_main, 0, 0, x_neg, y_neg, 'Color', colors(i,:), ...
                    'LineWidth', 0.8, 'MaxHeadSize', 0.3, 'LineStyle', '--');

                % 标注相位角
                if key_angles_deg(i) == 0
                    % 0度不需要重复标注
                elseif key_angles_deg(i) == 180
                    % 180度和-180度在同一位置，只标注一次
                else
                    text(ax_main, x_neg*1.15, y_neg*1.15, sprintf('-%d°', key_angles_deg(i)), ...
                        'FontSize', 7, 'Color', colors(i,:));
                end

                % 在单位圆上标记关键点（负频率）
                if key_angles_deg(i) ~= 0 && key_angles_deg(i) ~= 180
                    plot(ax_main, x_neg, y_neg, 's', 'MarkerSize', 8, ...
                        'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');
                end
            end

            axis(ax_main, 'equal');
            xlim(ax_main, [-1.5, 3.0]); % 调整x范围，为右移的sinθ投影留出空间
            ylim(ax_main, [-2.3, 2.3]);
            title(ax_main, '1. 复平面：正负频率向量', 'FontSize', 10, 'FontWeight', 'bold');
            xlabel(ax_main, '实轴 Re (cosθ)');
            ylabel(ax_main, '虚轴 Im (sinθ)');
            grid(ax_main, 'on');

            % 在复平面图内部绘制投影
            % 在右侧绘制sinθ投影：x轴为θ，y轴为sinθ
            sin_theta = linspace(0, 2*pi, 100);
            sin_x = sin_theta / (2*pi) * 0.6 + 1.8;  % 映射到[1.8, 2.4]
            sin_y = sin(sin_theta);  % 振幅±1

            % 绘制正频率sinθ曲线（实线）
            plot(ax_main, sin_x, sin_y, 'g-', 'LineWidth', 1.5, 'Color', [0, 0.7, 0]);

            % 绘制负频率sin(-θ)曲线（虚线）
            sin_y_neg = sin(-sin_theta);
            plot(ax_main, sin_x, sin_y_neg, 'g--', 'LineWidth', 1.5, 'Color', [0, 0.7, 0]);

            % 绘制sinθ投影的坐标轴
            plot(ax_main, [1.8, 2.4], [0, 0], 'g-', 'LineWidth', 1, 'Color', [0, 0.7, 0]);  % x轴
            plot(ax_main, [1.8, 1.8], [-1, 1], 'g-', 'LineWidth', 1, 'Color', [0, 0.7, 0]);  % y轴

            % 标注sinθ投影
            text(ax_main, 1.8, -1.2, '正负频率sinθ投影', 'FontSize', 8, 'Color', [0, 0.7, 0], ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(ax_main, 2.4, 0, 'θ', 'FontSize', 7, 'Color', [0, 0.7, 0], 'VerticalAlignment', 'top');
            text(ax_main, 1.75, 1, 'sinθ', 'FontSize', 7, 'Color', [0, 0.7, 0], ...
                'HorizontalAlignment', 'right');
            text(ax_main, 1.75, -1, 'sin(-θ)', 'FontSize', 7, 'Color', [0, 0.7, 0], ...
                'HorizontalAlignment', 'right');

            % 在上方绘制正频率cosθ投影：x轴为cosθ，y轴为θ
            cos_theta = linspace(0, 2*pi, 100);
            cos_x = cos(cos_theta);  % 振幅±1
            cos_y = cos_theta / (2*pi) * 0.6 + 1.5;  % 映射到[1.5, 2.1]

            % 绘制正频率cosθ曲线（实线）
            plot(ax_main, cos_x, cos_y, 'r-', 'LineWidth', 1.5, 'Color', [1, 0.5, 0]);

            % 在下方绘制负频率cosθ投影
            cos_y_neg = -1.5 - cos_theta / (2*pi) * 0.6;  % 映射到[-1.5, -2.1]

            % 绘制负频率cos(-θ)曲线（虚线）
            plot(ax_main, cos_x, cos_y_neg, 'r:', 'LineWidth', 1.5, 'Color', [1, 0.5, 0]);

            % 绘制正频率cosθ投影的坐标轴（上方）
            plot(ax_main, [-1, 1], [1.5, 1.5], 'r-', 'LineWidth', 1, 'Color', [1, 0.5, 0]);  % x轴
            plot(ax_main, [0, 0], [1.5, 2.1], 'r-', 'LineWidth', 1, 'Color', [1, 0.5, 0]);  % y轴

            % 绘制负频率cosθ投影的坐标轴（下方）
            plot(ax_main, [-1, 1], [-1.5, -1.5], 'r-', 'LineWidth', 1, 'Color', [1, 0.5, 0]);  % x轴
            plot(ax_main, [0, 0], [-2.0, -1.4], 'r-', 'LineWidth', 1, 'Color', [1, 0.5, 0]);  % y轴

            % 标注cosθ投影
            text(ax_main, -0.8, 2.1, '正频率cosθ投影', 'FontSize', 8, 'Color', [1, 0.5, 0], ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(ax_main, -0.8, -2.1, '负频率cosθ投影', 'FontSize', 8, 'Color', [1, 0.5, 0], ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            text(ax_main, 1.05, 1.5, 'cosθ', 'FontSize', 7, 'Color', [1, 0.5, 0], ...
                'VerticalAlignment', 'top');
            text(ax_main, 0, 2.1, 'θ', 'FontSize', 7, 'Color', [1, 0.5, 0], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            text(ax_main, 1.05, -1.6, 'cos(-θ)', 'FontSize', 7, 'Color', [1, 0.5, 0], ...
                'VerticalAlignment', 'top');
            text(ax_main, 0, -1.4, 'θ', 'FontSize', 7, 'Color', [1, 0.5, 0], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

            % 在三角函数投影上标记关键点并绘制连接线
            % 先标注sinθ和cosθ投影的关键角度点
            sin_key_angles = [0, pi/2, pi, 3*pi/2, 2*pi];
            sin_key_labels = {'0', 'π/2', 'π', '3π/2', '2π'};

            for i = 1:length(sin_key_angles)
                angle = sin_key_angles(i);

                % sinθ投影的x位置
                sin_x_pos = angle/(2*pi)*0.6 + 1.8;

                % 绘制sinθ投影刻度标记
                plot(ax_main, sin_x_pos, -0.08, 'g^', 'MarkerSize', 4, 'MarkerFaceColor', [0, 0.7, 0]);
                text(ax_main, sin_x_pos, -0.18, sin_key_labels{i}, 'FontSize', 6, 'Color', [0, 0.7, 0], ...
                    'HorizontalAlignment', 'center');

                % cosθ投影的y位置（正频率）
                cos_y_pos = angle/(2*pi)*0.6 + 1.5;
                % cosθ投影的y位置（负频率）
                cos_y_neg_pos = -angle/(2*pi)*0.6 - 1.5;

                % 绘制cosθ投影刻度标记（正频率）
                plot(ax_main, -0.08, cos_y_pos, 'r>', 'MarkerSize', 4, 'MarkerFaceColor', [1, 0.5, 0]);
                text(ax_main, 0.06, cos_y_pos, sin_key_labels{i}, 'FontSize', 6, 'Color', [1, 0.5, 0], ...
                    'VerticalAlignment', 'middle');

                % 绘制cosθ投影刻度标记（负频率）
                plot(ax_main, -0.08, cos_y_neg_pos, 'r>', 'MarkerSize', 4, 'MarkerFaceColor', [1, 0.5, 0]);
                text(ax_main, 0.06, cos_y_neg_pos, sin_key_labels{i}, 'FontSize', 6, 'Color', [1, 0.5, 0], ...
                    'VerticalAlignment', 'middle');
            end

            % 对每个关键角度点，在投影曲线上标记并绘制连接线
            for i = 1:length(key_angles)
                angle_pos = key_angles(i);
                angle_neg = -key_angles(i);

                % 计算在sinθ投影上的位置
                sin_proj_x = angle_pos/(2*pi)*0.6 + 1.8;
                sin_proj_y_pos = sin(angle_pos);  % 正频率
                sin_proj_y_neg = sin(angle_neg);  % 负频率

                % 在sinθ投影上标记关键点
                plot(ax_main, sin_proj_x, sin_proj_y_pos, 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1);
                plot(ax_main, sin_proj_x, sin_proj_y_neg, 's', 'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1);

                % 计算在cosθ投影上的位置
                cos_proj_x_pos = cos(angle_pos);
                cos_proj_x_neg = cos(angle_neg);
                cos_proj_y = angle_pos/(2*pi)*0.6 + 1.5;  % 正频率投影的y位置
                cos_proj_y_neg = -1.5 - angle_pos/(2*pi)*0.6;  % 负频率投影的y位置

                % 在cosθ投影上标记关键点
                plot(ax_main, cos_proj_x_pos, cos_proj_y, 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1);
                plot(ax_main, cos_proj_x_neg, cos_proj_y_neg, 's', 'MarkerSize', 8, ...
                    'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', 'LineWidth', 1);

                % 从复平面上的关键点到投影图绘制连接线
                % 正频率到sinθ投影
                plot(ax_main, [cos(angle_pos), sin_proj_x], [sin(angle_pos), sin_proj_y_pos], ...
                    ':', 'LineWidth', 0.5, 'Color', colors(i,:));

                % 正频率到cosθ投影
                plot(ax_main, [cos(angle_pos), cos_proj_x_pos], [sin(angle_pos), cos_proj_y], ...
                    ':', 'LineWidth', 0.5, 'Color', colors(i,:));

                % 负频率到sinθ投影
                plot(ax_main, [cos(angle_neg), sin_proj_x], [sin(angle_neg), sin_proj_y_neg], ...
                    ':', 'LineWidth', 0.5, 'Color', colors(i,:));

                % 负频率到cosθ投影
                plot(ax_main, [cos(angle_neg), cos_proj_x_neg], [sin(angle_neg), cos_proj_y_neg], ...
                    ':', 'LineWidth', 0.5, 'Color', colors(i,:));
            end

            % 添加图例
            legend_handles = [
                plot(ax_main, NaN, NaN, 'b-', 'LineWidth', 1.5);
                plot(ax_main, NaN, NaN, 'b--', 'LineWidth', 1.5);
                plot(ax_main, NaN, NaN, 'g-', 'LineWidth', 1.5, 'Color', [0, 0.7, 0]);
                plot(ax_main, NaN, NaN, 'g--', 'LineWidth', 1.5, 'Color', [0, 0.7, 0]);
                plot(ax_main, NaN, NaN, 'r-', 'LineWidth', 1.5, 'Color', [1, 0.5, 0]);
                plot(ax_main, NaN, NaN, 'r--', 'LineWidth', 1.5, 'Color', [1, 0.5, 0]);
            ];

            legend_labels = {
                '正频率向量 e^{iθ}';
                '负频率向量 e^{-iθ}';
                'sinθ (正频率)';
                'sin(-θ) = -sinθ (负频率)';
                'cosθ (正频率)';
                'cos(-θ) = cosθ (负频率)';
            };

            legend(ax_main, legend_handles, legend_labels, ...
                'Location', 'northeast', 'FontSize', 6);

            hold(ax_main, 'off');

            % 子图2：3D螺旋线，投影在独立平面上
            ax2 = subplot(1, 2, 2, 'Parent', obj.displayPanel);

            % 增加1个周期，从4π增加到6π
            t_3d = linspace(0, 6*pi, 300);

            % 正频率螺旋线：e^{iθ} = cosθ + i·sinθ
            spiral_x_pos = cos(t_3d);    % 实部：cos投影
            spiral_y_pos = sin(t_3d);    % 虚部：sin投影
            spiral_z = t_3d/(2*pi);      % 时间轴

            % 绘制3D螺旋线（主曲线）- 正频率
            plot3(ax2, spiral_x_pos, spiral_y_pos, spiral_z, 'b-', 'LineWidth', 2);
            hold(ax2, 'on');

            % 负频率螺旋线：e^{-iθ} = cosθ - i·sinθ（灰色，虚线）
            spiral_x_neg = cos(t_3d);     % 实部相同：cosθ
            spiral_y_neg = -sin(t_3d);    % 虚部相反：-sinθ

            % 绘制负频率螺旋线（灰色虚线）
            plot3(ax2, spiral_x_neg, spiral_y_neg, spiral_z, 'Color', [0.6, 0.6, 0.6], ...
                'LineWidth', 1.5, 'LineStyle', '--');

            % 绘制坐标轴
            plot3(ax2, [-2, 2], [0, 0], [0, 0], 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5]);
            plot3(ax2, [0, 0], [-2, 2], [0, 0], 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5]);
            plot3(ax2, [0, 0], [0, 0], [0, max(spiral_z)], 'k--', 'LineWidth', 1, 'Color', [0.5, 0.5, 0.5]);

            % 绘制单位圆（在z=0平面）
            circle_t = linspace(0, 2*pi, 100);
            plot3(ax2, cos(circle_t), sin(circle_t), zeros(size(circle_t)), 'r:', 'LineWidth', 1);

            % 正频率投影
            % 实部投影在独立平面（y = 2平面）
            plot3(ax2, cos(t_3d), 2*ones(size(t_3d)), spiral_z, 'r-', 'LineWidth', 1, 'Color', [1, 0.5, 0]);

            % 虚部投影在独立平面（x = -2平面）
            plot3(ax2, -2*ones(size(t_3d)), sin(t_3d), spiral_z, 'g-', 'LineWidth', 1, 'Color', [0, 0.7, 0]);

            % 负频率投影
            % 负频率实部投影：在y=2.2平面，实部为cosθ（虚线）
            plot3(ax2, cos(t_3d), 2.2*ones(size(t_3d)), spiral_z, 'r--', 'LineWidth', 1, 'Color', [1, 0.5, 0]);

            % 负频率虚部投影：在x=-2.0平面，虚部为-sinθ（虚线）
            plot3(ax2, -2.0*ones(size(t_3d)), -sin(t_3d), spiral_z, 'g--', 'LineWidth', 1, 'Color', [0, 0.7, 0]);

            % 定义需要标注的关键时间点
            key_times = 0:pi/2:6*pi;

            % 创建所有需要标注的时间值列表
            label_times = [1.5*pi, 2*pi, 3*pi, 4*pi, 5*pi, 6*pi];

            for t_val = key_times
                idx = find(abs(t_3d - t_val) < 0.1, 1);
                if ~isempty(idx)
                    % 正频率螺旋线上的点
                    plot3(ax2, spiral_x_pos(idx), spiral_y_pos(idx), spiral_z(idx), ...
                        'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');

                    % 负频率螺旋线上的点
                    plot3(ax2, spiral_x_neg(idx), spiral_y_neg(idx), spiral_z(idx), ...
                        'ks', 'MarkerSize', 6, 'MarkerFaceColor', [0.6, 0.6, 0.6]);

                    % 正频率实部投影点
                    plot3(ax2, spiral_x_pos(idx), 2, spiral_z(idx), ...
                        'ro', 'MarkerSize', 5, 'MarkerFaceColor', [1, 0.5, 0]);

                    % 正频率虚部投影点
                    plot3(ax2, -2, spiral_y_pos(idx), spiral_z(idx), ...
                        'go', 'MarkerSize', 5, 'MarkerFaceColor', [0, 0.7, 0]);

                    % 负频率实部投影点
                    plot3(ax2, spiral_x_neg(idx), 2.2, spiral_z(idx), ...
                        'rs', 'MarkerSize', 5, 'MarkerFaceColor', [1, 0.5, 0]);

                    % 负频率虚部投影点
                    plot3(ax2, -2.0, spiral_y_neg(idx), spiral_z(idx), ...
                        'gs', 'MarkerSize', 5, 'MarkerFaceColor', [0, 0.7, 0]);

                    % 标注特定时间值
                    if any(abs(t_val - label_times) < 0.1)
                        text_str = '';
                        if abs(t_val - 1.5*pi) < 0.1
                            text_str = '1.5π';
                        elseif abs(t_val - 2*pi) < 0.1
                            text_str = '2π';
                        elseif abs(t_val - 3*pi) < 0.1
                            text_str = '3π';
                        elseif abs(t_val - 4*pi) < 0.1
                            text_str = '4π';
                        elseif abs(t_val - 5*pi) < 0.1
                            text_str = '5π';
                        elseif abs(t_val - 6*pi) < 0.1
                            text_str = '6π';
                        end

                        if ~isempty(text_str)
                            % 调整文本位置，避免重叠
                            x_offset = 0.3;
                            y_offset = 0;
                            z_offset = 0.1;

                            % 对于某些点，调整偏移量以避免重叠
                            if abs(t_val - 1.5*pi) < 0.1
                                x_offset = -0.4;
                                y_offset = 0.2;
                            elseif abs(t_val - 3*pi) < 0.1
                                x_offset = 0.4;
                                y_offset = -0.2;
                            elseif abs(t_val - 4*pi) < 0.1
                                x_offset = -0.4;
                            elseif abs(t_val - 5*pi) < 0.1
                                x_offset = 0.4;
                            end

                            text(ax2, spiral_x_pos(idx)+x_offset, spiral_y_pos(idx)+y_offset, spiral_z(idx)+z_offset, ...
                                text_str, 'FontSize', 7, 'FontWeight', 'bold');
                        end
                    end
                end
            end

            % 在3D螺旋线上标记子图1的关键角度点
            for i = 1:length(key_angles)
                angle = key_angles(i);

                % 找到最近的时间点
                [~, idx] = min(abs(t_3d - angle));

                if ~isempty(idx)
                    % 正频率螺旋线上的点（使用与子图1相同的颜色）
                    plot3(ax2, spiral_x_pos(idx), spiral_y_pos(idx), spiral_z(idx), ...
                        'o', 'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');

                    % 负频率螺旋线上的点
                    plot3(ax2, spiral_x_neg(idx), spiral_y_neg(idx), spiral_z(idx), ...
                        's', 'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');

                    % 正频率实部投影点
                    plot3(ax2, spiral_x_pos(idx), 2, spiral_z(idx), ...
                        'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');

                    % 正频率虚部投影点
                    plot3(ax2, -2, spiral_y_pos(idx), spiral_z(idx), ...
                        'o', 'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');

                    % 负频率实部投影点
                    plot3(ax2, spiral_x_neg(idx), 2.2, spiral_z(idx), ...
                        's', 'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');

                    % 负频率虚部投影点
                    plot3(ax2, -2.0, spiral_y_neg(idx), spiral_z(idx), ...
                        's', 'MarkerSize', 6, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k');
                end
            end

            % 绘制投影连接线（从螺旋线到投影平面的虚线）
            sample_indices = 1:30:length(t_3d);  % 每30个点取一个
            for idx = sample_indices
                % 正频率螺旋线到实部投影的连接线（虚线）
                plot3(ax2, [spiral_x_pos(idx), spiral_x_pos(idx)], ...
                              [spiral_y_pos(idx), 2], ...
                              [spiral_z(idx), spiral_z(idx)], ...
                              ':', 'LineWidth', 0.5, 'Color', [1, 0.5, 0]);

                % 正频率螺旋线到虚部投影的连接线（虚线）
                plot3(ax2, [spiral_x_pos(idx), -2], ...
                              [spiral_y_pos(idx), spiral_y_pos(idx)], ...
                              [spiral_z(idx), spiral_z(idx)], ...
                              ':', 'LineWidth', 0.5, 'Color', [0, 0.7, 0]);

                % 负频率螺旋线到实部投影的连接线（虚线，灰色）
                plot3(ax2, [spiral_x_neg(idx), spiral_x_neg(idx)], ...
                              [spiral_y_neg(idx), 2.2], ...
                              [spiral_z(idx), spiral_z(idx)], ...
                              ':', 'LineWidth', 0.5, 'Color', [0.7, 0.7, 0.7]);

                % 负频率螺旋线到虚部投影的连接线（虚线，灰色）
                plot3(ax2, [spiral_x_neg(idx), -2.0], ...
                              [spiral_y_neg(idx), spiral_y_neg(idx)], ...
                              [spiral_z(idx), spiral_z(idx)], ...
                              ':', 'LineWidth', 0.5, 'Color', [0.7, 0.7, 0.7]);
            end

            % 添加平面标注
            text(ax2, 1.8, 2, max(spiral_z), '正频率实部投影', ...
                'FontSize', 8, 'Color', [1, 0.5, 0], 'HorizontalAlignment', 'center');
            text(ax2, -2, -1.8, max(spiral_z)*0.95, '正频率虚部投影', ...
                'FontSize', 8, 'Color', [0, 0.7, 0], 'HorizontalAlignment', 'center');

            text(ax2, 1.8, 2.2, max(spiral_z)*0.9, '负频率实部投影', ...
                'FontSize', 8, 'Color', [1, 0.5, 0], 'HorizontalAlignment', 'center');
            text(ax2, -2.0, -1.8, max(spiral_z)*0.85, '负频率虚部投影', ...
                'FontSize', 8, 'Color', [0, 0.7, 0], 'HorizontalAlignment', 'center');

            % 调整视角和坐标轴范围
            view(ax2, 45, 30);
            xlabel(ax2, '实部 (cosθ)');
            ylabel(ax2, '虚部 (sinθ)');
            zlabel(ax2, '时间 t');
            title(ax2, '2. 3D螺旋线：e^{iθ} = cosθ + i·sinθ', 'FontSize', 10, 'FontWeight', 'bold');
            grid(ax2, 'on');

            % 设置坐标轴范围
            xlim(ax2, [-2.5, 2.5]);
            ylim(ax2, [-2.5, 2.5]);
            zlim(ax2, [0, max(spiral_z)]);

            % 添加图例
            legend(ax2, {'正频率 e^{iθ}螺旋线', '负频率 e^{-iθ}螺旋线', '坐标轴', '单位圆', ...
                         '正频率实部投影', '正频率虚部投影', '负频率实部投影', '负频率虚部投影'}, ...
                'Location', 'best', 'FontSize', 7);

            hold(ax2, 'off');

            sgtitle('步骤5：欧拉公式与复平面', 'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤6：傅里叶变换原理 - 对比傅里叶级数和傅里叶变换
        function showFourierTransformPrinciple(obj)
            %SHOWFOURIERTRANSFORMPRINCIPLE 步骤6——傅里叶级数与傅里叶变换对比
            %   3×3布局：时域周期/非周期信号、双边/单边离散谱、双边/单边连续谱。
            T = 2*pi;          % 周期显式定义为2π
            pulse_width = T/2; % 脉冲宽度 τ = T/2

            % ========== 布局：3行×3列 ==========

            % ========== 子图1：时域周期方波（5个完整周期） ==========
            ax1 = subplot(3, 3, 1, 'Parent', obj.displayPanel);
            t_periodic = linspace(-2.5*T, 2.5*T, 3000);   % 5个周期（-2.5T ~ 2.5T）
            periodic_square_wave = zeros(size(t_periodic));
            for i = -2:2                                 % 5个脉冲：-2,-1,0,1,2
                start_time = i*T - pulse_width/2;
                end_time = i*T + pulse_width/2;
                periodic_square_wave(t_periodic >= start_time & t_periodic <= end_time) = 1;
            end
            plot(ax1, t_periodic/T, periodic_square_wave, 'b', 'LineWidth', 1.5);
            title(ax1, '1. 偶对称周期方波（显示5个完整周期）', 'FontSize', 10);
            xlabel(ax1, '归一化时间 t/T');
            ylabel(ax1, '振幅');
            grid(ax1, 'on');
            xlim(ax1, [-2.5, 2.5]);
            xticks(ax1, [-2, -1, 0, 1, 2]);
            xticklabels(ax1, {'-2T', '-T', '0', 'T', '2T'});
            ylim(ax1, [-0.2, 1.2]);
            hold(ax1, 'on');

            % --- 脉冲宽度标注 ---
            plot(ax1, [-pulse_width/(2*T), -pulse_width/(2*T)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            plot(ax1, [ pulse_width/(2*T),  pulse_width/(2*T)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            text(ax1, 0, -0.1, '周期 T = 2\pi', 'FontSize', 9, 'HorizontalAlignment', 'center');
            text(ax1, pulse_width/T, 1.1, '\tau = T/2', 'FontSize', 8, 'Color', 'r', ...
                 'HorizontalAlignment', 'left');
            hold(ax1, 'off');

            % ========== 子图2：时域单个矩形脉冲 ==========
            ax2 = subplot(3, 3, 2, 'Parent', obj.displayPanel);
            t_single = linspace(-2.5*T, 2.5*T, 2000);
            tau = pulse_width;
            rect_pulse = zeros(size(t_single));
            rect_pulse(abs(t_single) <= tau/2) = 1;
            plot(ax2, t_single/T, rect_pulse, 'b', 'LineWidth', 2);
            title(ax2, '2. 单个矩形脉冲（非周期）', 'FontSize', 10);
            xlabel(ax2, '归一化时间 t/T');
            ylabel(ax2, '振幅');
            grid(ax2, 'on');
            xlim(ax2, [-2.5, 2.5]);
            xticks(ax2, [-2, -1, 0, 1, 2]);
            xticklabels(ax2, {'-2T', '-T', '0', 'T', '2T'});
            ylim(ax2, [-0.2, 1.2]);
            hold(ax2, 'on');
            plot(ax2, [-tau/(2*T), -tau/(2*T)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            plot(ax2, [ tau/(2*T),  tau/(2*T)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            text(ax2, 0, -0.1, '脉冲宽度 \tau = T/2', ...
                'FontSize', 9, 'HorizontalAlignment', 'center');
            hold(ax2, 'off');

            % ========== 子图3：时域高斯信号 ==========
            ax3 = subplot(3, 3, 3, 'Parent', obj.displayPanel);
            t_gauss = linspace(-2*T, 2*T, 1000);
            sigma = T/3;
            gauss_signal = exp(-t_gauss.^2/(2*sigma^2));
            plot(ax3, t_gauss/T, gauss_signal, 'b', 'LineWidth', 2);
            title(ax3, '3. 时域：高斯信号', 'FontSize', 10);
            xlabel(ax3, '归一化时间 t/T');
            ylabel(ax3, '振幅');
            grid(ax3, 'on');
            xlim(ax3, [-1.5, 1.5]);
            xticks(ax3, [-1.5, -1, -0.5, 0, 0.5, 1, 1.5]);
            xticklabels(ax3, {'-1.5T', '-T', '-T/2', '0', 'T/2', 'T', '1.5T'});
            ylim(ax3, [-0.1, 1.1]);
            hold(ax3, 'on');
            plot(ax3, [-sigma/T, sigma/T], [exp(-0.5), exp(-0.5)], 'r--', 'LineWidth', 1);
            text(ax3, 0, exp(-0.5)-0.05, '\sigma = T/3', ...
                'FontSize', 9, 'HorizontalAlignment', 'center');
            hold(ax3, 'off');

            % ========== 子图4：傅里叶级数双边离散谱（直流洋红色，零点灰色） ==========
            ax4 = subplot(3, 3, 4, 'Parent', obj.displayPanel);
            n_range = -10:10;
            coefficients = zeros(size(n_range));
            for i = 1:length(n_range)
                n = n_range(i);
                if n == 0
                    coefficients(i) = tau / T;
                else
                    coefficients(i) = (tau/T) * sinc(n * tau / T);
                end
            end
            hold(ax4, 'on');
            % 绘制各分量
            for i = 1:length(n_range)
                n = n_range(i);
                if n == 0
                    stem(ax4, n, coefficients(i), 'm', 'LineWidth', 1.5, ...
                         'MarkerSize', 7, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
                elseif mod(n,2) == 1
                    stem(ax4, n, coefficients(i), 'b', 'LineWidth', 1.5, ...
                         'MarkerSize', 5, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                else
                    % 偶次谐波（零振幅）灰色空心圆点
                    plot(ax4, n, 0, 'o', 'MarkerSize', 5, ...
                         'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                end
            end
            % 包络线
            f_envelope = linspace(-10/T, 10/T, 1000);
            envelope = (tau/T) * sinc(f_envelope * tau);
            plot(ax4, f_envelope*T, envelope, 'k--', 'LineWidth', 1);
            title(ax4, '4. 频域：傅里叶级数（双边离散谱）', 'FontSize', 10);
            xlabel(ax4, '归一化频率 n');
            ylabel(ax4, '傅里叶系数 c_n');
            grid(ax4, 'on');
            xlim(ax4, [-10.5, 10.5]);
            ylim(ax4, [-0.13, max(coefficients)*1.1]);  % 负值可见
            plot(ax4, [0, 0], ylim(ax4), 'k:', 'LineWidth', 0.5);
            text(ax4, 1.0, max(coefficients)*0.95, 'c_n = (\tau/T) sinc(n\tau/T)', ...
                'FontSize', 6);
            % legend(ax4, {'直流分量', '奇次谐波', '偶次谐波(零)', 'sinc包络'}, 'Location', 'northwest', 'FontSize', 6);
            hold(ax4, 'off');

            % ========== 子图5：傅里叶变换连续谱（标注所有零点） ==========
            ax5 = subplot(3, 3, 5, 'Parent', obj.displayPanel);
            f = linspace(-10/T, 10/T, 2000);
            sinc_func = tau * sinc(f * tau);
            plot(ax5, f*T, sinc_func, 'b', 'LineWidth', 2);
            title(ax5, '5. 频域：傅里叶变换（连续sinc函数）', 'FontSize', 10);
            xlabel(ax5, '归一化频率 f·T');
            ylabel(ax5, '幅度 F(\omega)');
            grid(ax5, 'on');
            xlim(ax5, [-10, 10]);
            hold(ax5, 'on');
            % 标注所有零点（±2,±4,±6,±8,±10）
            for k = -5:5
                if k == 0, continue; end
                zero_point = k / tau;
                zero_norm = zero_point * T;
                if abs(zero_norm) <= 10
                    plot(ax5, zero_norm, 0, 'o', 'MarkerSize', 5, ...
                         'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                end
            end
            plot(ax5, [0, 0], ylim(ax5), 'k:', 'LineWidth', 0.5);
            text(ax5, 0, max(sinc_func)*1.10, 'F(\omega) = \tau·sinc(\omega\tau)', ...
                'FontSize', 8, 'HorizontalAlignment', 'center');
            hold(ax5, 'off');

            % ========== 子图6：高斯信号的傅里叶变换 ==========
            ax6 = subplot(3, 3, 6, 'Parent', obj.displayPanel);
            f_gauss = linspace(-4/T, 4/T, 1000);
            gauss_ft = sqrt(2*pi)*sigma * exp(-(2*pi*f_gauss*sigma).^2/2);
            plot(ax6, f_gauss*T, gauss_ft, 'b', 'LineWidth', 2);
            title(ax6, '6. 频域：高斯函数的傅里叶变换', 'FontSize', 10);
            xlabel(ax6, '归一化频率 f·T');
            ylabel(ax6, '幅度 F(\omega)');
            grid(ax6, 'on');
            xlim(ax6, [-4, 4]);
            hold(ax6, 'on');
            plot(ax6, [0, 0], ylim(ax6), 'k:', 'LineWidth', 0.5);
            text(ax6, 0, max(gauss_ft)*1.08, 'F(\omega) = \surd(2\pi)\sigma·e^{-(\omega\sigma)²/2}', ...
                'FontSize', 8, 'HorizontalAlignment', 'center');
            hold(ax6, 'off');

            % ========== 子图7：傅里叶级数单边谱（直流洋红色，零点灰色，Y轴负值可见） ==========
            ax7 = subplot(3, 3, 7, 'Parent', obj.displayPanel);
            n_pos = 0:10;
            coeff_pos = zeros(size(n_pos));
            for i = 1:length(n_pos)
                n = n_pos(i);
                if n == 0
                    coeff_pos(i) = tau / T;          % 周期平均值
                else
                    coeff_pos(i) = 2 * (tau/T) * sinc(n * tau / T);
                end
            end
            hold(ax7, 'on');
            % n=0：洋红色
            stem(ax7, 0, coeff_pos(1), 'm', 'LineWidth', 1.5, ...
                 'MarkerSize', 7, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
            % 奇次谐波：蓝色
            for i = 2:length(n_pos)
                n = n_pos(i);
                if mod(n,2) == 1
                    stem(ax7, n, coeff_pos(i), 'b', 'LineWidth', 1.5, ...
                         'MarkerSize', 5, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                else
                    % 偶次谐波（零振幅）灰色空心圆点
                    plot(ax7, n, 0, 'o', 'MarkerSize', 6, ...
                         'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                end
            end
            title(ax7, '7. 傅里叶级数单边谱', 'FontSize', 10);
            xlabel(ax7, '谐波阶数 n');
            ylabel(ax7, '振幅');
            grid(ax7, 'on');
            xlim(ax7, [-0.5, 10.5]);
            ylim(ax7, [-0.25, max(coeff_pos)*1.1]);  % 负值可见
            text(ax7, 5, max(coeff_pos)*0.55, 'n=0: 周期平均值 = τ/T', 'FontSize', 7, ...
                 'HorizontalAlignment', 'center');
            text(ax7, 5, max(coeff_pos)*0.4, 'n>0: 2|c_n| (奇次)', 'FontSize', 7, ...
                 'HorizontalAlignment', 'center');
            legend(ax7, {'直流分量(平均值)', '奇次谐波', '偶次谐波(零)'}, 'Location', 'northeast', 'FontSize', 6);
            hold(ax7, 'off');

            % ========== 子图8：傅里叶变换单边谱（直流用洋红色stem，Y轴负值可见） ==========
            ax8 = subplot(3, 3, 8, 'Parent', obj.displayPanel);
            f_pos = linspace(0, 10/T, 2000);
            f_positive = f_pos(f_pos > 0);
            sinc_func_pos = tau * sinc(f_positive * tau);
            % f>0：连续曲线，幅度翻倍
            plot(ax8, f_positive*T, 2*sinc_func_pos, 'b', 'LineWidth', 2);
            hold(ax8, 'on');
            % f=0：直流分量 = 脉冲面积 = τ，使用洋红色 stem（带线）
            stem(ax8, 0, tau, 'm', 'LineWidth', 1.5, ...
                 'MarkerSize', 8, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
            % 标注零点
            for k = 1:5
                zero_point = k / tau;
                zero_norm = zero_point * T;
                if zero_norm <= 10
                    plot(ax8, zero_norm, 0, 'o', 'MarkerSize', 5, ...
                         'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                end
            end
            title(ax8, '8. 傅里叶变换单边谱', 'FontSize', 10);
            xlabel(ax8, '归一化频率 f·T');
            ylabel(ax8, '幅度 F(\omega)');
            grid(ax8, 'on');
            xlim(ax8, [0, 10]);
            ylim(ax8, [-1.6, max(2*sinc_func_pos)*1.2]);  % 负值可见
            plot(ax8, [0, 0], ylim(ax8), 'k:', 'LineWidth', 0.5);
            text(ax8, 5, max(2*sinc_func_pos)*0.9, ...
                 'f=0: 脉冲面积 τ,  f>0: 2τ·sinc(fτ)', ...
                 'FontSize', 7, 'HorizontalAlignment', 'center');
            hold(ax8, 'off');

            % ========== 子图9：高斯函数傅里叶变换单边谱（直流用洋红色stem，Y轴负值可见） ==========
            ax9 = subplot(3, 3, 9, 'Parent', obj.displayPanel);
            f_gauss_pos = linspace(0, 4/T, 2000);
            f_gauss_positive = f_gauss_pos(f_gauss_pos > 0);
            gauss_ft_pos = sqrt(2*pi)*sigma * exp(-(2*pi*f_gauss_positive*sigma).^2/2);
            % f>0：连续曲线，幅度翻倍
            plot(ax9, f_gauss_positive*T, 2*gauss_ft_pos, 'b', 'LineWidth', 2);
            hold(ax9, 'on');
            % f=0：直流分量 = 积分值 = √(2π)σ，洋红色 stem
            stem(ax9, 0, sqrt(2*pi)*sigma, 'm', 'LineWidth', 1.5, ...
                 'MarkerSize', 8, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
            title(ax9, '9. 高斯函数傅里叶变换单边谱', 'FontSize', 10);
            xlabel(ax9, '归一化频率 f·T');
            ylabel(ax9, '幅度 F(\omega)');
            grid(ax9, 'on');
            xlim(ax9, [0, 4]);
            ylim(ax9, [-0.05, max(2*gauss_ft_pos)*1.2]);  % 负值可见
            plot(ax9, [0, 0], ylim(ax9), 'k:', 'LineWidth', 0.5);
            text(ax9, 2, max(2*gauss_ft_pos)*0.9, ...
                 'f=0: 积分值 √(2π)σ,  f>0: 2·F(f)', ...
                 'FontSize', 7, 'HorizontalAlignment', 'center');
            hold(ax9, 'off');

            sgtitle('步骤6：傅里叶级数与傅里叶变换原理对比（含单边谱）', ...
                    'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤7：指数形式傅里叶变换
        function showExponentialForm(obj)
            %SHOWEXPONENTIALFORM 步骤7——指数形式的傅里叶变换
            %   3×3布局展示正向变换（乘积）、核函数（3D螺旋线）、频谱及反向合成。
            % 正向：时域→频域（左列）   核函数（中列）   反向：频域→时域（右列）

            % ---------- 信号定义（矩形脉冲，宽度 tau = pi） ----------
            tau = pi;                    % 脉冲宽度
            t_sig = linspace(-3, 3, 500); % 时域显示范围
            rect = double(abs(t_sig) <= tau/2); % 矩形脉冲
            area_rect = tau;            % 信号面积（直流分量值）

            % ---------- 频率选择 ----------
            omega_zero = 2;             % 第二个零点（不合适频率）
            omega_match = 0;           % 直流（匹配频率，积分最大）
            omega_semi = 1;            % 半匹配频率（新加）

            % ---------- 频谱函数（解析） ----------
            omega_axis = linspace(-5, 5, 300);
            F_omega = tau * sinc(omega_axis / 2);  % 因 tau=pi，sinc参数 ωτ/(2π)=ω/2

            % ---------- 反向合成：前几个非零频率分量 ----------
            omega_harmonics = 0:1:5;    % 选取 0,1,2,3,4,5
            F_vals = tau * sinc(omega_harmonics / 2); % 频谱系数
            t_recon = linspace(-3, 3, 1000);
            recon_signal = zeros(size(t_recon));
            for k = 1:length(omega_harmonics)
                w = omega_harmonics(k);
                recon_signal = recon_signal + F_vals(k) * cos(w * t_recon) / (2*pi);
                % 反向变换积分因子：1/(2π) ∫ F(ω) e^{iωt} dω，单频时实部为 F(ω)cos(ωt)/(2π)
            end

            % ---------- 创建3×3布局 ----------
            sgtitle('步骤7：指数形式傅里叶变换 —— 正向·核·反向', ...
                    'FontSize', 14, 'FontWeight', 'bold');

            % ========== 左列：正向变换过程 ==========
            % 子图1：原始信号 f(t)
            ax1 = subplot(3,3,1, 'Parent', obj.displayPanel);
            plot(ax1, t_sig, rect, 'b-', 'LineWidth', 2);
            title(ax1, '1. 原始信号 f(t) (矩形脉冲)');
            xlabel(ax1, '时间 t'); ylabel(ax1, '振幅');
            grid(ax1, 'on'); xlim(ax1, [-3,3]); ylim(ax1, [-0.1, 1.2]);
            hold(ax1, 'on');
            plot(ax1, [-tau/2, -tau/2], [-0.1,1.2], 'r--', 'LineWidth',1);
            plot(ax1, [ tau/2,  tau/2], [-0.1,1.2], 'r--', 'LineWidth',1);
            text(ax1, 0, 0.5, sprintf('\\tau = %.2f', tau), ...
                 'HorizontalAlignment','center', 'Color','r');
            hold(ax1, 'off');

            % 子图4：不匹配频率 ω=2（零点）—— 乘积 f(t)·e^{-iωt} 的实部/虚部
            ax4 = subplot(3,3,4, 'Parent', obj.displayPanel);
            prod_real = rect .* cos(-omega_zero * t_sig);
            prod_imag = rect .* sin(-omega_zero * t_sig);
            plot(ax4, t_sig, prod_real, 'r-', 'LineWidth',1.5); hold(ax4,'on');
            plot(ax4, t_sig, prod_imag, 'g-', 'LineWidth',1.5);
            plot(ax4, t_sig, zeros(size(t_sig)), 'k:');
            hold(ax4,'off');
            title(ax4, sprintf('4. 不匹配频率 ω = %d (零点)', omega_zero));
            xlabel(ax4, '时间 t'); ylabel(ax4, '振幅');
            legend(ax4, {'实部', '虚部'}, 'Location','southeast', 'FontSize',8);
            grid(ax4,'on'); xlim(ax4, [-3,3]); ylim(ax4, [-2.0,1.4]);

            % 子图7：匹配频率 ω=0（直流）—— 乘积 = f(t) 本身
            ax7 = subplot(3,3,7, 'Parent', obj.displayPanel);
            plot(ax7, t_sig, rect, 'b-', 'LineWidth',2); hold(ax7,'on');
            % 显示积分面积（阴影）
            t_fill = t_sig(abs(t_sig)<=tau/2);
            rect_fill = ones(size(t_fill));
            fill(ax7, [t_fill, fliplr(t_fill)], [zeros(size(t_fill)), fliplr(rect_fill)], ...
                 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            hold(ax7,'off');
            title(ax7, sprintf('7. 匹配频率 ω = %d (直流)', omega_match));
            xlabel(ax7, '时间 t'); ylabel(ax7, '振幅');
            text(ax7, 0, 0.5, sprintf('积分 = %.2f', area_rect), ...
                 'HorizontalAlignment','center', 'FontSize',10, 'FontWeight','bold');
            grid(ax7,'on'); xlim(ax7, [-3,3]); ylim(ax7, [-0.1,1.2]);

            % ========== 中列：傅里叶变换核库（3D螺旋线）==========
            % 合并子图2、5、8为一个大的3D坐标轴
            ax_mid = subplot(3,3,[2,5,8], 'Parent', obj.displayPanel);
            t_spiral = linspace(0, 2*pi, 300);   % 只显示一圈，避免混乱
            omega_list = [1, 2, 3];              % 三个典型频率
            colors = lines(length(omega_list));

            hold(ax_mid, 'on'); grid(ax_mid, 'on');
            % 绘制 e^{-iωt} 螺旋线
            for k = 1:length(omega_list)
                w = omega_list(k);
                x = cos(w * t_spiral);        % 实部
                y = -sin(w * t_spiral);       % 虚部（注意负号：正向变换核）
                z = t_spiral;                % 时间轴
                plot3(ax_mid, x, y, z, 'Color', colors(k,:), 'LineWidth', 2);
            end
            % 坐标轴
            plot3(ax_mid, [-1.2,1.2], [0,0], [0,2*pi], 'k--', 'LineWidth',0.5);
            plot3(ax_mid, [0,0], [-1.2,1.2], [0,2*pi], 'k--', 'LineWidth',0.5);
            plot3(ax_mid, [0,0], [0,0], [0,2*pi], 'k-', 'LineWidth',1);
            % 单位圆（t=0平面）
            theta = linspace(0,2*pi,100);
            plot3(ax_mid, cos(theta), sin(theta), zeros(size(theta)), 'k:', 'LineWidth',1);
            % 固定视角与范围
            view(ax_mid, 35, 20);
            xlim(ax_mid, [-1.2,1.2]); ylim(ax_mid, [-1.2,1.2]); zlim(ax_mid, [0,2*pi]);
            xlabel(ax_mid, '实部 Re(e^{-i\omegat})');
            ylabel(ax_mid, '虚部 Im(e^{-i\omegat})');
            zlabel(ax_mid, '时间 t');
            title(ax_mid, '傅里叶变换核  e^{-i\omegat}   (ω=1,2,3)');
            legend(ax_mid, arrayfun(@(w) sprintf('ω = %d', w), omega_list, 'UniformOutput', false), ...
                   'Location', 'northeast', 'FontSize',8);
            hold(ax_mid, 'off');

            % ========== 右列：频域及反向变换 ==========
            % 子图3：频谱 F(ω) (实函数)
            ax3 = subplot(3,3,3, 'Parent', obj.displayPanel);
            plot(ax3, omega_axis, F_omega, 'b-', 'LineWidth', 2); hold(ax3,'on');
            % 标注 ω = 0,1,2,3 的点
            omega_markers = [0,1,2,3];
            F_markers = tau * sinc(omega_markers/2);
            stem(ax3, omega_markers, F_markers, 'r', 'LineWidth',1.5, ...
                 'MarkerSize',8, 'MarkerFaceColor','r');
            % 添加数值标签
            for k = 1:length(omega_markers)
                text(ax3, omega_markers(k)+0.1, F_markers(k)+0.1, ...
                     sprintf('%.2f', F_markers(k)), 'FontSize',8);
            end
            hold(ax3,'off');
            title(ax3, '3. 频谱 F(\omega) (实部)');
            xlabel(ax3, '频率 \omega'); ylabel(ax3, 'F(\omega)');
            legend(ax3, {'F(\omega)', '标注点'}, 'Location', 'northeast', 'FontSize',7);
            grid(ax3,'on'); xlim(ax3, [-5,5]); ylim(ax3, [-1, 3.5]);

            % 子图6：正向变换，半匹配频率 ω=1
            ax6 = subplot(3,3,6, 'Parent', obj.displayPanel);
            prod_real_semi = rect .* cos(-omega_semi * t_sig);  % 实部 = cos(ωt)
            prod_imag_semi = rect .* sin(-omega_semi * t_sig);  % 虚部 = -sin(ωt)
            plot(ax6, t_sig, prod_real_semi, 'r-', 'LineWidth',1.5); hold(ax6,'on');
            plot(ax6, t_sig, prod_imag_semi, 'g-', 'LineWidth',1.5);
            plot(ax6, t_sig, zeros(size(t_sig)), 'k:');
            hold(ax6,'off');
            title(ax6, sprintf('6. 正向变换: ω = %d (半匹配)', omega_semi));
            xlabel(ax6, '时间 t'); ylabel(ax6, '振幅');
            legend(ax6, {'实部', '虚部'}, 'Location','southeast', 'FontSize',8);
            grid(ax6,'on'); xlim(ax6, [-3,3]); ylim(ax6, [-2.0, 1.4]);

            % 子图9：反向合成（多个频率分量叠加）
            ax9 = subplot(3,3,9, 'Parent', obj.displayPanel);
            plot(ax9, t_recon, recon_signal, 'b-', 'LineWidth',2); hold(ax9,'on');
            plot(ax9, t_sig, rect, 'r--', 'LineWidth',1.5); % 原始信号参考
            hold(ax9,'off');
            title(ax9, '9. 反向合成: (1/2π)Σ F(ω_n) e^{iω_nt}');
            xlabel(ax9, '时间 t'); ylabel(ax9, '振幅');
            legend(ax9, {'合成信号', '原始信号'}, 'Location','southeast', 'FontSize',7);
            grid(ax9,'on'); xlim(ax9, [-3,3]); ylim(ax9, [-0.6, 1.3]);
        end

        % 步骤8：采样定理——完全采样与混叠
        function showSamplingTheorem(obj)
            %SHOWSAMPLINGTHEOREM 步骤8——采样定理：完全采样与混叠
            %   3×2布局：正常采样(时域/频域)、欠采样混叠(时域/频域)、
            %   混叠频率关系(锯齿图)、NMR谱宽与折叠(fold-over)。
            f0     = 3;      % 信号频率 (Hz)
            fsGood = 8;      % 满足采样定理：fs > 2f0
            fsBad  = 4;      % 欠采样：fs < 2f0
            Twin   = 1;      % 显示时长 (s)
            t = linspace(0, Twin, 4000);
            x = sin(2*pi*f0*t);

            % ===== 子图1：满足采样定理——时域采样与复原 =====
            ax1 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 1, 0.105, 0.15, 0.09));
            tsGood = 0:1/fsGood:Twin;
            xsGood = sin(2*pi*f0*tsGood);
            plot(ax1, t, x, 'b-', 'LineWidth', 1.6); hold(ax1, 'on');
            stem(ax1, tsGood, xsGood, 'r', 'LineWidth', 1, ...
                'MarkerSize', 5, 'MarkerFaceColor', 'r');
            plot(ax1, t, x, 'g--', 'LineWidth', 1.3);
            hold(ax1, 'off'); grid(ax1, 'on');
            xlim(ax1, [0, Twin]); ylim(ax1, [-1.6, 2.8]);   % 顶部留白避免图例盖住波形
            xlabel(ax1, '时间 (s)'); ylabel(ax1, '幅度');
            title(ax1, sprintf('1. 满足采样定理：f_s=%.0f Hz > 2f_0=%.0f Hz', ...
                fsGood, 2*f0), 'FontSize', 10);
            legend(ax1, {'真实信号', '采样点', '恢复信号'}, ...
                'Location', 'northeast', 'FontSize', 8);
            text(ax1, Twin/2, -1.45, '采样足够密 → 可无失真复原', ...
                'FontSize', 8, 'Color', [0, 0.5, 0], ...
                'HorizontalAlignment', 'center');

            % ===== 子图2：满足采样定理——频谱周期延拓不重叠 =====
            ax2 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 2, 0.105, 0.15, 0.09));
            fmax2 = 2*fsGood;
            replica = sort([f0, fsGood - f0, fsGood + f0, ...
                2*fsGood - f0, 2*fsGood + f0]);
            replica = replica(replica >= 0 & replica <= fmax2);
            hold(ax2, 'on');
            patch(ax2, [0 fsGood/2 fsGood/2 0], [0 0 1.2 1.2], ...
                [0.6 1 0.6], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
            for k = 1:numel(replica)
                if abs(replica(k) - f0) < 1e-9
                    stem(ax2, replica(k), 1, 'b', 'LineWidth', 1.5, ...
                        'MarkerFaceColor', 'b');
                else
                    stem(ax2, replica(k), 1, 'Color', [0.45 0.45 0.85], ...
                        'LineWidth', 1.2, 'MarkerFaceColor', [0.45 0.45 0.85]);
                end
            end
            plot(ax2, [fsGood/2 fsGood/2], [0 1.25], 'k--', 'LineWidth', 1.1);
            hold(ax2, 'off'); grid(ax2, 'on');
            xlim(ax2, [0, fmax2]); ylim(ax2, [0, 1.45]);
            xlabel(ax2, '频率 (Hz)'); ylabel(ax2, '相对幅度');
            title(ax2, '2. 采样频谱：以 f_s 为周期延拓，各副本不重叠', ...
                'FontSize', 10);
            text(ax2, fsGood/2, 1.28, 'f_s/2', 'FontSize', 8, ...
                'HorizontalAlignment', 'center');
            text(ax2, f0, 1.08, 'f_0', 'FontSize', 8, 'Color', 'b', ...
                'HorizontalAlignment', 'center');
            text(ax2, fsGood - f0, 1.08, 'f_s-f_0', 'FontSize', 8, ...
                'Color', [0.3 0.3 0.7], 'HorizontalAlignment', 'center');

            % ===== 子图3：欠采样——时域采样点伪装成低频信号 =====
            ax3 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 3, 0.105, 0.15, 0.09));
            tsBad = 0:1/fsBad:Twin;
            xsBad = sin(2*pi*f0*tsBad);
            fEff  = f0 - fsBad*round(f0/fsBad);   % 有符号等效(别名)频率
            xa    = sin(2*pi*fEff*t);
            plot(ax3, t, x, 'b-', 'LineWidth', 1.6); hold(ax3, 'on');
            stem(ax3, tsBad, xsBad, 'r', 'LineWidth', 1, ...
                'MarkerSize', 6, 'MarkerFaceColor', 'r');
            plot(ax3, t, xa, 'm--', 'LineWidth', 1.6);
            hold(ax3, 'off'); grid(ax3, 'on');
            xlim(ax3, [0, Twin]); ylim(ax3, [-1.6, 2.8]);   % 顶部留白避免图例盖住波形
            xlabel(ax3, '时间 (s)'); ylabel(ax3, '幅度');
            title(ax3, sprintf('3. 欠采样：f_s=%.0f Hz < 2f_0=%.0f Hz', ...
                fsBad, 2*f0), 'FontSize', 10);
            legend(ax3, {'真实信号 (3 Hz)', '采样点', ...
                sprintf('恢复信号 (%.0f Hz 假象)', abs(fEff))}, ...
                'Location', 'northeast', 'FontSize', 8);
            text(ax3, Twin/2, -1.45, '采样点落在 1 Hz 正弦波上 → 无法分辨', ...
                'FontSize', 8, 'Color', [0.8, 0, 0], ...
                'HorizontalAlignment', 'center');

            % ===== 子图4：欠采样——频谱折叠(混叠) =====
            ax4 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 4, 0.105, 0.15, 0.09));
            fmax4 = 2*fsBad;
            hold(ax4, 'on');
            patch(ax4, [0 fsBad/2 fsBad/2 0], [0 0 1.2 1.2], ...
                [1 0.8 0.8], 'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
            stem(ax4, f0, 1, 'b', 'LineWidth', 1.6, 'MarkerFaceColor', 'b');
            stem(ax4, abs(fEff), 1, 'r', 'LineWidth', 1.6, ...
                'MarkerFaceColor', 'r');
            plot(ax4, [fsBad/2 fsBad/2], [0 1.25], 'k--', 'LineWidth', 1.1);
            hold(ax4, 'off'); grid(ax4, 'on');
            xlim(ax4, [0, fmax4]); ylim(ax4, [0, 1.45]);
            xlabel(ax4, '频率 (Hz)'); ylabel(ax4, '相对幅度');
            title(ax4, '4. 频谱重叠：3 Hz 越过 f_s/2 折叠为 1 Hz', ...
                'FontSize', 10);
            text(ax4, fsBad/2, 1.28, 'f_s/2', 'FontSize', 8, ...
                'HorizontalAlignment', 'center');
            text(ax4, f0, 1.08, '真实 3 Hz', 'FontSize', 8, 'Color', 'b', ...
                'HorizontalAlignment', 'center');
            text(ax4, abs(fEff), 0.85, '混叠 1 Hz', 'FontSize', 8, ...
                'Color', 'r', 'HorizontalAlignment', 'center');

            % ===== 子图5：混叠频率关系（锯齿图） =====
            ax5 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 5, 0.105, 0.15, 0.09));
            fr  = linspace(0, 3*fsBad, 3000);
            fAl = abs(fr - fsBad*round(fr/fsBad));
            hold(ax5, 'on');
            patch(ax5, [0 fsBad/2 fsBad/2 0], ...
                [0 0 fsBad/2+0.3 fsBad/2+0.3], ...
                [0.6 1 0.6], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
            plot(ax5, fr, fAl, 'b-', 'LineWidth', 1.8);
            plot(ax5, [0 3*fsBad], [fsBad/2 fsBad/2], 'k--', 'LineWidth', 1.1);
            plot(ax5, f0, abs(fEff), 'ro', 'MarkerSize', 8, ...
                'MarkerFaceColor', 'r');
            hold(ax5, 'off'); grid(ax5, 'on');
            xlim(ax5, [0, 3*fsBad]); ylim(ax5, [0, fsBad/2+0.3]);
            xlabel(ax5, '真实频率 f (Hz)'); ylabel(ax5, '观察到的频率 (Hz)');
            title(ax5, '5. 混叠频率关系（f_s=4 Hz）：超过 f_s/2 折返', ...
                'FontSize', 10);
            text(ax5, f0 + 0.15, abs(fEff), '← 3 Hz→1 Hz', ...
                'FontSize', 8, 'Color', 'r');
            text(ax5, fsBad/2*0.5, fsBad/2+0.12, ...
                '无混叠区 (f < f_s/2)', 'FontSize', 8, ...
                'Color', [0 0.5 0], 'HorizontalAlignment', 'center');

            % ===== 子图6：NMR应用——谱宽SW与折叠(fold-over) =====
            ax6 = axes('Parent', obj.displayPanel, 'Units', 'normalized', ...
                'Position', obj.subplotPos(3, 2, 6, 0.105, 0.15, 0.09));
            SW  = 20;                                  % 谱宽 (kHz, 示意)
            off = linspace(-SW/2, SW/2, 2000);
            genuine = exp(-((off - 4)/0.6).^2);        % 真实峰：+4 kHz
            folded  = exp(-((off + 7)/0.6).^2);        % 折叠峰：-7 kHz
            plot(ax6, off, genuine, 'b-', 'LineWidth', 1.8); hold(ax6, 'on');
            plot(ax6, off, folded, 'r--', 'LineWidth', 1.8);
            hold(ax6, 'off'); grid(ax6, 'on');
            xlim(ax6, [-SW/2, SW/2]); ylim(ax6, [-0.3, 1.25]);
            xlabel(ax6, '相对载频的偏移频率 (kHz)'); ylabel(ax6, '幅度');
            title(ax6, '6. NMR：谱宽 SW=1/dwell，可无混叠观测 ±SW/2', ...
                'FontSize', 10);
            text(ax6, 4, 1.12, '真实峰', 'FontSize', 8, 'Color', 'b', ...
                'HorizontalAlignment', 'center');
            text(ax6, -7, 1.12, '折叠峰', 'FontSize', 8, 'Color', 'r', ...
                'HorizontalAlignment', 'center');
            text(ax6, 0, -0.2, ...
                '真实位置 +13 kHz（> +SW/2）→ 折叠到 -7 kHz', ...
                'FontSize', 8, 'Color', 'r', 'HorizontalAlignment', 'center');

            % 交互演示按钮（布局已在底部预留按钮带，避免按钮盖住子图）
            uicontrol('Parent', obj.displayPanel, ...
                'Style', 'pushbutton', ...
                'String', '▶ 启动采样混叠交互演示', ...
                'Units', 'normalized', ...
                'Position', [0.2, 0.02, 0.6, 0.07], ...
                'FontSize', 12, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1, 0.9, 0.8], ...
                'Callback', @(src,event) obj.launchSamplingDemo());

            sgtitle('步骤8：采样定理——完全采样与避免混叠', ...
                'FontSize', 14, 'FontWeight', 'bold');
        end

         % 步骤9：NMR脉冲调制 - 傅里叶变换的实际应用
        function showNMRPulseTransition(obj)
            %SHOWNMRPULSETRANSITION 步骤9——NMR脉冲调制应用
            %   3×3布局：无限/有限脉冲序列时域、双边/单边频谱对比、实际NMR参数示例。
            T0 = 2*pi;
            tau = T0/4;
        
            % ========== 子图1：理想周期方波（时域） ==========
            ax1 = subplot(3, 3, 1, 'Parent', obj.displayPanel);
            t1 = linspace(-2.5*T0, 2.5*T0, 2000);
            square_wave = zeros(size(t1));
            for i = -2:2
                start_time = i*T0 - tau/2;
                end_time = i*T0 + tau/2;
                square_wave(t1 >= start_time & t1 <= end_time) = 1;
            end
            plot(ax1, t1/T0, square_wave, 'b', 'LineWidth', 1.5);
            title(ax1, '无限长周期方波(\tau = T/4)', 'FontSize', 10);
            xlabel(ax1, '归一化时间 t/T'); ylabel(ax1, '振幅');
            grid(ax1, 'on'); xlim(ax1, [-2.5, 2.5]); ylim(ax1, [-0.2, 1.2]);
            % 标注周期 T 和脉冲宽度 τ
            hold(ax1, 'on');
            plot(ax1, [-tau/(2*T0), -tau/(2*T0)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            plot(ax1, [ tau/(2*T0),  tau/(2*T0)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            text(ax1, 0.5, -0.1, '周期 T = 2\pi', 'FontSize', 9, 'HorizontalAlignment', 'center');
            text(ax1, tau/T0, 1.1, '\tau = T/4', 'FontSize', 8, 'Color', 'r', ...
                 'HorizontalAlignment', 'left');
            % 设置 x 轴刻度标签
            xticks(ax1, [-2, -1, 0, 1, 2]);
            xticklabels(ax1, {'-2T', '-T', '0', 'T', '2T'});
            hold(ax1, 'off');
        
            % ========== 子图2：有限长脉冲序列（时域） ==========
            ax2 = subplot(3, 3, 2, 'Parent', obj.displayPanel);
            t2 = linspace(-3*T0, 3*T0, 2000);
            finite_seq = zeros(size(t2));
            for i = -1:1
                start_time = i*T0 - tau/2;
                end_time = i*T0 + tau/2;
                finite_seq(t2 >= start_time & t2 <= end_time) = 1;
            end
            plot(ax2, t2/T0, finite_seq, 'b', 'LineWidth', 1.5);
            title(ax2, '有限时长方波(3个周期，\tau = T/4)', 'FontSize', 10);
            xlabel(ax2, '归一化时间 t/T'); ylabel(ax2, '振幅');
            grid(ax2, 'on'); xlim(ax2, [-2, 2]); ylim(ax2, [-0.2, 1.2]);
            % 标注中间脉冲的宽度 τ
            hold(ax2, 'on');
            plot(ax2, [-tau/(2*T0), -tau/(2*T0)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            plot(ax2, [ tau/(2*T0),  tau/(2*T0)], [-0.2, 1.2], 'r--', 'LineWidth', 1);
            text(ax2, 0.6, 1.1, '\tau = T/4', 'FontSize', 8, 'Color', 'r', ...
                 'HorizontalAlignment', 'center');
            % 设置 x 轴刻度标签
            xticks(ax2, [-2, -1, 0, 1, 2]);
            xticklabels(ax2, {'-2T', '-T', '0', 'T', '2T'});
            hold(ax2, 'off');
        
            % ========== 子图3：NMR脉冲调制（时域，整体视图，x轴-0.5~1.5） ==========
            ax3 = subplot(3, 3, 3, 'Parent', obj.displayPanel);
            % 实际参数：脉冲宽度 50 μs，周期 1 s，脉冲起始于 0 s 和 1 s，显示范围 -0.5～1.5 s
            tau_us = 50;                % 脉冲宽度（μs）
            T_s = 1;                    % 周期（秒）
            fc_MHz = 400;               % 载频（MHz）
            % 时间轴：-0.5 到 1.5 秒，包含两个完整脉冲
            t_s = linspace(-0.5, 1.5, 50000);
            % 构建包络：两个矩形脉冲，宽度 tau_us，起始时间分别为 0 s 和 1 s
            pulse_envelope = zeros(size(t_s));
            tau_s = tau_us * 1e-6;      % 转换为秒
            start_t1 = 0;
            end_t1 = start_t1 + tau_s;
            start_t2 = 1;
            end_t2 = start_t2 + tau_s;
            pulse_envelope(t_s >= start_t1 & t_s <= end_t1) = 1;
            pulse_envelope(t_s >= start_t2 & t_s <= end_t2) = 1;
            % 调制信号：载频 400 MHz
            modulated_signal = pulse_envelope .* cos(2*pi*fc_MHz * t_s * 1e6); % fc_MHz 转 Hz
            plot(ax3, t_s, modulated_signal, 'b', 'LineWidth', 0.5);
            hold(ax3, 'on');
            plot(ax3, t_s, pulse_envelope, 'r', 'LineWidth', 1.5);
            plot(ax3, t_s, -pulse_envelope, 'r', 'LineWidth', 1.5);
            title(ax3, '3. NMR脉冲调制（时域，整体）', 'FontSize', 10);
            xlabel(ax3, '时间 (s)'); ylabel(ax3, '振幅');
            grid(ax3, 'on'); xlim(ax3, [-0.5, 1.5]);
            % 标注脉冲宽度和周期
            text(ax3, start_t1 + 0.3, 0.5, sprintf('τ = %d μs', tau_us), 'FontSize', 8, 'Color', 'r', ...
                 'HorizontalAlignment', 'center');
            text(ax3, start_t1 + T_s/2, 1.1, sprintf('T = 1 s'), 'FontSize', 8, 'Color', 'b', ...
                 'HorizontalAlignment', 'center');
            % 设置 x 轴刻度
            xticks(ax3, [-0.5, 0, 0.5, 1, 1.5]);
            xticklabels(ax3, {'-0.5', '0', '0.5', '1', '1.5'});
            % 用矩形框标出第一个脉冲的放大区域（0 s 到 0 + 0.5 μs）
            zoom_width = 0.5e-6; % 0.5 μs
            rectangle(ax3, 'Position', [start_t1, -1.2, zoom_width, 2.4], ...
                      'EdgeColor', 'k', 'LineStyle', '--', 'LineWidth', 1);
            hold(ax3, 'off');
        
            % ========== 子图4：傅里叶级数双边离散谱 ==========
            ax4 = subplot(3, 3, 4, 'Parent', obj.displayPanel);
            n_range = -10:10;
            frequencies = n_range / T0;
            coefficients = zeros(size(n_range));
            for i = 1:length(n_range)
                n = n_range(i);
                if n == 0
                    coefficients(i) = tau / T0;
                else
                    coefficients(i) = (tau/T0) * sinc(n * tau / T0);
                end
            end
            hold(ax4, 'on');
            % 绘制各频率分量
            for i = 1:length(n_range)
                n = n_range(i);
                if n == 0
                    % 直流：洋红色
                    stem(ax4, frequencies(i)*T0, coefficients(i), 'm', 'LineWidth', 1.5, ...
                        'MarkerSize', 7, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
                elseif abs(coefficients(i)) < 1e-12
                    % 零振幅点：灰色空心圆点
                    plot(ax4, frequencies(i)*T0, 0, 'o', 'MarkerSize', 6, ...
                        'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                else
                    % 非零振幅（无论奇偶）：蓝色
                    stem(ax4, frequencies(i)*T0, coefficients(i), 'b', 'LineWidth', 1.5, ...
                        'MarkerSize', 5, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                end
            end
            % 包络线
            f_envelope = linspace(-10/T0, 10/T0, 1000);
            envelope = (tau/T0) * sinc(f_envelope * tau);
            plot(ax4, f_envelope*T0, envelope, 'k--', 'LineWidth', 1);
            title(ax4, '4. 傅里叶级数双边谱', 'FontSize', 10);
            xlabel(ax4, '归一化频率 n'); ylabel(ax4, '傅里叶系数 c_n');
            grid(ax4, 'on'); xlim(ax4, [-10.5, 10.5]);
            ylim(ax4, [min(coefficients)*1.2, max(coefficients)*1.2]);
            plot(ax4, [0, 0], ylim(ax4), 'k:', 'LineWidth', 0.5);
        
            hold(ax4, 'off');
        
            % ========== 子图5：有限序列双边谱（无绝对值，含包络） ==========
            ax5 = subplot(3, 3, 5, 'Parent', obj.displayPanel);
            f5 = linspace(-5/T0, 5/T0, 1000);
            single_pulse_spectrum = tau * sinc(f5 * tau);
            N_pulses = 3;
            pulse_spacing = T0;
            pulse_seq_spectrum = single_pulse_spectrum .* sinc(f5 * pulse_spacing * N_pulses);
            plot(ax5, f5*T0, pulse_seq_spectrum, 'b', 'LineWidth', 1.5);
            hold(ax5, 'on');
            plot(ax5, f5*T0, single_pulse_spectrum, 'k--', 'LineWidth', 1);
            title(ax5, '5. 有限序列双边谱', 'FontSize', 10);
            xlabel(ax5, '归一化频率 f·T'); ylabel(ax5, '幅度');
            grid(ax5, 'on'); xlim(ax5, [-5, 5]);
            text(ax5, -3, max(pulse_seq_spectrum)*1.15, '包络: 单个脉冲频谱', ...
                'FontSize', 8, 'Color', 'k');
            main_lobe_width = 1/tau;
            plot(ax5, [-main_lobe_width*T0/2, main_lobe_width*T0/2], ...
                [max(abs(pulse_seq_spectrum))*0.5, max(abs(pulse_seq_spectrum))*0.5], 'r--', 'LineWidth', 1);
            text(ax5, 0, max(abs(pulse_seq_spectrum))*0.55, 'Δf ≈ 1/τ', ...
                'FontSize', 8, 'HorizontalAlignment', 'center');
            hold(ax5, 'off');
        
            % ========== 子图6：NMR脉冲双边谱（实际参数，相对中心频率） ==========
            ax6 = subplot(3, 3, 6, 'Parent', obj.displayPanel);
            % 使用实际参数：τ = 50 μs，频率范围 ±100 kHz（相对400 MHz载频）
            tau_us_ft = 50;                 % 脉冲宽度（μs）
            f_offset_kHz = linspace(-100, 100, 2000);   % 偏移频率范围 -100 kHz 到 100 kHz
            f_offset_MHz = f_offset_kHz / 1000;         % 转换为 MHz 用于 sinc 计算
            % 正确公式：F(f) = τ * sinc(f * τ)，其中 τ 单位 μs，f 单位 MHz，乘积无量纲
            pulse_spectrum = tau_us_ft * sinc(f_offset_MHz * tau_us_ft);
            plot(ax6, f_offset_kHz, pulse_spectrum, 'b', 'LineWidth', 1.5);
            title(ax6, '6. NMR脉冲双边谱', 'FontSize', 10);
            xlabel(ax6, '偏移频率 (kHz)'); ylabel(ax6, '幅度');
            grid(ax6, 'on'); xlim(ax6, [-100, 100]);
            hold(ax6, 'on');
            excitation_bandwidth_kHz = 1000 / tau_us_ft;  % 转换为 kHz = 20 kHz
            bw_points = excitation_bandwidth_kHz;
            plot(ax6, [-bw_points/2, bw_points/2], ...
                [max(abs(pulse_spectrum))*0.5, max(abs(pulse_spectrum))*0.5], 'r-', 'LineWidth', 1.0);
            text(ax6, 0, max(abs(pulse_spectrum))*1.1, sprintf('激发带宽 ≈ 1/τ = %.0f kHz', excitation_bandwidth_kHz), ...
                'FontSize', 8, 'HorizontalAlignment', 'center');
            zero_points_kHz = [-1000/tau_us_ft, 1000/tau_us_ft];   % kHz, 即 ±20 kHz
            plot(ax6, zero_points_kHz(1), 0, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
            plot(ax6, zero_points_kHz(2), 0, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
            hold(ax6, 'off');

        
            % ========== 子图7：傅里叶级数单边谱（按零点修正，n>0幅度加倍） ==========
            ax7 = subplot(3, 3, 7, 'Parent', obj.displayPanel);
            n_pos = 0:10;
            coeff_single = zeros(size(n_pos));
            for i = 1:length(n_pos)
                n = n_pos(i);
                if n == 0
                    coeff_single(i) = tau / T0;          % 直流保持
                else
                    coeff_single(i) = 2 * (tau/T0) * sinc(n * tau / T0);
                end
            end
            hold(ax7, 'on');
            % 绘制各频率分量
            for i = 1:length(n_pos)
                n = n_pos(i);
                if n == 0
                    stem(ax7, n, coeff_single(i), 'm', 'LineWidth', 1.5, ...
                        'MarkerSize', 8, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
                elseif abs(coeff_single(i)) < 1e-12
                    plot(ax7, n, 0, 'o', 'MarkerSize', 6, ...
                        'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0.5 0.5 0.5]);
                else
                    stem(ax7, n, coeff_single(i), 'b', 'LineWidth', 1.5, ...
                        'MarkerSize', 6, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
                end
            end
            % 包络线
            n_cont = linspace(0, 10, 500);
            envelope_single = 2 * (tau/T0) * sinc(n_cont * tau / T0);
            plot(ax7, n_cont, envelope_single, 'k--', 'LineWidth', 1);
        
            title(ax7, '7. 傅里叶级数单边谱', 'FontSize', 10);
            xlabel(ax7, '谐波阶数 n'); ylabel(ax7, '系数 (单边)');
            grid(ax7, 'on'); xlim(ax7, [-0.5, 10.5]);
            ylim(ax7, [min(coeff_single)*1.2, max(coeff_single)*1.2]);
            text(ax7, 5.5, max(coeff_single)*0.6, 'n=0: τ/T₀, n>0: 2c_n', ...
                'FontSize', 8, 'HorizontalAlignment', 'center');
            hold(ax7, 'off');
        
            % ========== 子图8：有限序列单边谱（直流用洋红色，f>0加倍） ==========
            ax8 = subplot(3, 3, 8, 'Parent', obj.displayPanel);
            f8_pos = linspace(0, 5/T0, 500);
            single_pulse_spectrum_pos = tau * sinc(f8_pos * tau);
            N_pulses = 3;
            pulse_spacing = T0;
            pulse_seq_spectrum_pos = single_pulse_spectrum_pos .* sinc(f8_pos * pulse_spacing * N_pulses);
            % 单边谱：f>0 加倍，直流不变
            pulse_seq_single = pulse_seq_spectrum_pos;
            pulse_seq_single(2:end) = 2 * pulse_seq_spectrum_pos(2:end);
            plot(ax8, f8_pos*T0, pulse_seq_single, 'b', 'LineWidth', 1.5);
            hold(ax8, 'on');
            % 包络线：单个脉冲的单边谱
            single_pulse_single = single_pulse_spectrum_pos;
            single_pulse_single(2:end) = 2 * single_pulse_spectrum_pos(2:end);
            plot(ax8, f8_pos*T0, single_pulse_single, 'k--', 'LineWidth', 1);
            % 直流点用洋红色 stem 突出
            stem(ax8, 0, pulse_seq_single(1), 'm', 'LineWidth', 1.5, ...
                'MarkerSize', 8, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
            title(ax8, '8. 有限序列单边谱', 'FontSize', 10);
            xlabel(ax8, '归一化频率 f·T'); ylabel(ax8, '幅度');
            grid(ax8, 'on'); xlim(ax8, [0, 5]);
            ylim(ax8, [min(pulse_seq_single)*1.2, max(pulse_seq_single)*1.2]);
            text(ax8, 1.5, max(pulse_seq_single)*0.9, '包络: 单个脉冲单边谱', ...
                'FontSize', 8, 'Color', 'k');
            hold(ax8, 'off');
        
            % ========== 子图9：NMR脉冲单边谱（实际参数，相对中心频率） ==========
            ax9 = subplot(3, 3, 9, 'Parent', obj.displayPanel);
            % 单边谱，偏移频率 0～100 kHz
            f_offset_kHz_pos = linspace(0, 100, 2000);
            f_offset_MHz_pos = f_offset_kHz_pos / 1000;
            pulse_spectrum_pos = tau_us_ft * sinc(f_offset_MHz_pos * tau_us_ft);
            pulse_spectrum_single = pulse_spectrum_pos;
            pulse_spectrum_single(2:end) = 2 * pulse_spectrum_pos(2:end);
            plot(ax9, f_offset_kHz_pos, pulse_spectrum_single, 'b', 'LineWidth', 1.5);
            title(ax9, '9. NMR脉冲单边谱', 'FontSize', 10);
            xlabel(ax9, '偏移频率 (kHz)'); ylabel(ax9, '幅度');
            grid(ax9, 'on'); xlim(ax9, [0, 100]);
            ylim(ax9, [min(pulse_spectrum_single)*1.2, max(pulse_spectrum_single)*1.2]);
            hold(ax9, 'on');
            
            % 在 f=0 处添加洋红色 stem 点，表示直流分量
            stem(ax9, 0, pulse_spectrum_single(1), 'm', 'LineWidth', 1.5, ...
                 'MarkerSize', 8, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
            
            % 标注激发带宽和零点
            excitation_bandwidth_kHz = 1000 / tau_us_ft;
            bw_points = excitation_bandwidth_kHz;
            plot(ax9, [0, bw_points], [max(abs(pulse_spectrum_single))*0.7, max(abs(pulse_spectrum_single))*0.7], ...
                'r--', 'LineWidth', 1.5);
            text(ax9,10, max(abs(pulse_spectrum_single))*0.85, ...
                sprintf('激发带宽 ≈ 1/τ = %.0f kHz', excitation_bandwidth_kHz), ...
                'FontSize', 8, 'HorizontalAlignment', 'left');
            zero_point_kHz = 1000 / tau_us_ft;
            plot(ax9, zero_point_kHz, 0, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
            hold(ax9, 'off');

            sgtitle('步骤9：NMR脉冲调制 - 傅里叶变换的应用实例（含单边谱对比）', ...
                'FontSize', 14, 'FontWeight', 'bold');

        end

        % === 步骤10 - NMR FID信号演示 ===
        function showFID(obj)
            %SHOWFID 步骤10——NMR自由感应衰减（FID）信号演示
            %   3×2布局：单一频率FID与频谱、三频率叠加、乙醇NMR谱完整模拟。
            % 修改后：子图1 = 带标注的单一频率FID；子图2 = 单一频率频谱
        
            % 时间轴参数（0~5秒，5000点）
            t = linspace(0, 5, 5000);
            T2 = 1.5;                       % 衰减时间常数 (s)
            envelope = exp(-t/T2);
        
            % === 定义频率（基于30 MHz谱仪，1 ppm = 30 Hz）===
            % 子图1&2：单一频率 3 Hz（演示用）
            f_single = 3;
        
            % 子图3：三个简单频率叠加（3,7,21 Hz）
            f3 = [3, 7, 21];
            amp3 = [1, 1.8, 0.6];
        
            % 子图4：乙醇甲基三重峰（化学位移 1.2 ppm -> 36 Hz，J=7 Hz）
            f_CH3_triplet = [36-7, 36, 36+7];   % [29, 36, 43] Hz
            amp_CH3_triplet = [1, 2, 1];        % 三重峰强度比
        
            % 子图5：乙醇完整FID（甲基三重峰 + 亚甲基四重峰 + 羟基单峰）
            % 亚甲基：化学位移 3.6 ppm -> 108 Hz，四重峰 J=7 Hz
            f_CH2_quartet = 108 + [-10.5, -3.5, 3.5, 10.5]; % 近似间隔7 Hz
            amp_CH2_quartet = [1, 3, 3, 1];      % 四重峰强度比
            % 羟基：化学位移 5 ppm -> 150 Hz，单峰（宽峰，此处简化）
            f_OH = 150;
            amp_OH = 1;
            % 合并所有频率和振幅
            f_ethanol = [f_CH3_triplet, f_CH2_quartet, f_OH];
            amp_ethanol = [amp_CH3_triplet, amp_CH2_quartet, amp_OH];
        
            % 计算各FID信号
            fid_single = envelope .* cos(2*pi*f_single*t);
        
            fid3 = zeros(size(t));
            for i = 1:length(f3)
                fid3 = fid3 + amp3(i) * envelope .* cos(2*pi*f3(i)*t);
            end
        
            fid_ethanol = zeros(size(t));
            for i = 1:length(f_ethanol)
                fid_ethanol = fid_ethanol + amp_ethanol(i) * envelope .* cos(2*pi*f_ethanol(i)*t);
            end
        
            % 计算单一频率FID的频谱（用于子图2）
            N = length(t);
            dt = t(2)-t(1);
            fs = 1/dt;                      % 采样频率 ≈ 1000 Hz
            fid_single_fft = fft(fid_single);
            freq = (0:N-1)*(fs/N);          % 频率轴
            halfN = floor(N/2)+1;
            mag_single = abs(fid_single_fft(1:halfN));   % 单边幅度
            freq_half = freq(1:halfN);
        
            % 计算三个频率叠加的频谱（用于子图4）
            fid3_fft = fft(fid3);
            mag3 = abs(fid3_fft(1:halfN));
        
            % 计算乙醇FID的频谱（用于子图6）
            fid_fft = fft(fid_ethanol);
            mag = abs(fid_fft(1:halfN));
        
            % 创建3×2子图
            % 子图1：单一频率FID，带周期竖虚线、T2*标注和能量公式（原子图2）
            ax1 = subplot(3,2,1, 'Parent', obj.displayPanel);
            plot(ax1, t, fid_single, 'b', 'LineWidth', 1.5);
            hold(ax1, 'on');
            plot(ax1, t,  envelope, 'r--', 'LineWidth', 1);
            plot(ax1, t, -envelope, 'r--', 'LineWidth', 1);
            % 计算周期并标注竖虚线
            [pks, locs] = findpeaks(fid_single, t, 'MinPeakHeight', 0.2*max(fid_single));
            if length(locs) >= 2
                period = mean(diff(locs(1:2)));
                % 在第一个和第二个峰值处画竖虚线
                y_lim = ylim(ax1);
                plot(ax1, [locs(1), locs(1)], y_lim, 'k:', 'LineWidth', 1.5);
                plot(ax1, [locs(2), locs(2)], y_lim, 'k:', 'LineWidth', 1.5);
                text(ax1, (locs(1)+locs(2))/2+0.3, y_lim(2)*0.9, sprintf('T = %.3f s', period), ...
                     'FontSize', 9, 'HorizontalAlignment', 'left');
            end
            % 标注T2*：找到包络第一次降到1/e的时间点
            idx_T2 = find(envelope <= exp(-1), 1, 'first');
            if ~isempty(idx_T2)
                t_T2 = t(idx_T2);
                plot(ax1, [t_T2, t_T2], [-exp(-1), exp(-1)], 'm--', 'LineWidth', 1.5);
                text(ax1, t_T2+0.1, exp(-1)+0.2, sprintf('T2* = %.2f s', T2), ...
                     'FontSize', 9);
            end    
            % 能量计算公式及数值
            energy = trapz(t, fid_single.^2);
            text(ax1, 0.2, 0.2, sprintf('E = ∫f²dt = %.3f', energy), ...
                 'Units', 'normalized', 'FontSize', 9, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
            xlabel(ax1, '时间 (s)'); ylabel(ax1, '幅度');
            title(ax1, sprintf('单一频率FID (f = %d Hz, 带标注)', f_single));
            grid(ax1, 'on'); xlim(ax1, [0,5]); ylim(ax1, [-1.2,1.2]);
            legend(ax1, {'FID', '包络线'}, 'Location', 'northeast');
            hold(ax1, 'off');
        
            % 子图2：单一频率FID的频谱（类似子图4、6），并标注半高宽与T2*关系
            ax2 = subplot(3,2,2, 'Parent', obj.displayPanel);
            plot(ax2, freq_half, mag_single, 'b', 'LineWidth', 1.5);
            set(ax2, 'XDir','reverse');      % 反向，左大右小（符合NMR习惯）
            xlabel(ax2, '频率 (Hz)');
            ylabel(ax2, '幅度');
            title(ax2, sprintf('单一频率频谱 (f = %d Hz)', f_single));
            grid(ax2, 'on');
            xlim(ax2, [0, 10]);  % 显示到25Hz
            % 标注峰值
            hold(ax2, 'on');
            [~, idx_peak] = min(abs(freq_half - f_single));
            peak_mag = mag_single(idx_peak);
            stem(ax2, freq_half(idx_peak), peak_mag, 'r', 'LineWidth', 1, 'MarkerSize', 6);
            text(ax2, freq_half(idx_peak)-0.5, peak_mag, sprintf('%d Hz', f_single), 'FontSize', 8);
            
            % 计算半高宽并标注（使用理论关系或实际测量）
            % 理论半高宽 (FWHM) 与 T2* 关系：Δν = 1/(π·T2*)
            FWHM_theory = 1/(pi * T2);  % 约0.212 Hz
            % 在实际频谱中找接近半高的点（由于分辨率有限，可能不精确，但示意）
            half_max = peak_mag / 2;
            % 向左找第一个低于半高的点
            idx_left = find(mag_single(1:idx_peak) <= half_max, 1, 'last');
            if isempty(idx_left)
                idx_left = 1;
            end
            f_left = freq_half(idx_left);
            % 向右找第一个低于半高的点
            idx_right = idx_peak + find(mag_single(idx_peak+1:end) <= half_max, 1, 'first');
            if isempty(idx_right)
                idx_right = length(freq_half);
            end
            f_right = freq_half(idx_right);
            FWHM_meas = f_right - f_left;
            % 绘制半高线
            plot(ax2, [f_left, f_right], [half_max, half_max], 'm-', 'LineWidth', 1.5);
            % 标注
            text(ax2, f_left + (f_right-f_left)/2+1, half_max*1.1, ...
                 sprintf('FWHM ≈ %.3f Hz\n(理论: 1/(πT2*) = %.3f Hz)', FWHM_meas, FWHM_theory), ...
                 'FontSize', 8, 'HorizontalAlignment', 'right');
            
            hold(ax2, 'off');
        
            % 子图3：三个简单频率叠加的时域FID
            ax3 = subplot(3,2,3, 'Parent', obj.displayPanel);
            plot(ax3, t, fid3, 'm', 'LineWidth', 1.5);
            hold(ax3, 'on');
            xlabel(ax3, '时间 (s)'); ylabel(ax3, '幅度');
            title(ax3, '三个简单频率叠加 (3,7,21 Hz)');
            grid(ax3, 'on'); xlim(ax3, [0,5]); ylim(ax3, [-4,4]);
            hold(ax3, 'off');
        
            % 子图4：三个频率叠加的频谱
            ax4 = subplot(3,2,4, 'Parent', obj.displayPanel);
            plot(ax4, freq_half, mag3, 'b', 'LineWidth', 1.5);
            set(ax4, 'XDir','reverse');
            xlabel(ax4, '频率 (Hz)');
            ylabel(ax4, '幅度');
            title(ax4, '三个频率的频谱');
            grid(ax4, 'on');
            xlim(ax4, [0, 25]);
            hold(ax4, 'on');
            for fi = f3
                [~, idx] = min(abs(freq_half - fi));
                stem(ax4, freq_half(idx), mag3(idx), 'r', 'LineWidth', 1, 'MarkerSize', 6);
                text(ax4, freq_half(idx)-0.5, mag3(idx)+0.2, sprintf('%d Hz', fi), 'FontSize', 8);
            end
            hold(ax4, 'off');
        
            % 子图5：乙醇完整FID时域
            ax5 = subplot(3,2,5, 'Parent', obj.displayPanel);
            plot(ax5, t, fid_ethanol, 'Color', [0.8,0.2,0.2], 'LineWidth', 0.8);
            hold(ax5, 'on');
            xlabel(ax5, '时间 (s)'); ylabel(ax5, '幅度');
            title(ax5, '乙醇 FID (甲基+亚甲基+羟基, 8个频率)');
            grid(ax5, 'on'); xlim(ax5, [0,5]); ylim(ax5, [-15,15]);
            hold(ax5, 'off');
        
            % 子图6：乙醇FID的傅里叶变换（NMR谱）
            ax6 = subplot(3,2,6, 'Parent', obj.displayPanel);
            plot(ax6, freq_half, mag, 'b', 'LineWidth', 1.5);
            set(ax6, 'XDir','reverse');
            xlabel(ax6, '频率 (Hz)');
            ylabel(ax6, '幅度');
            title(ax6, '乙醇 FID 的傅里叶变换（30 MHz NMR谱）');
            grid(ax6, 'on');
            xlim(ax6, [0, 200]);
            hold(ax6, 'on');
            % 标注主要峰群（甲基区域、亚甲基区域、羟基）
            [~, idx_CH3] = min(abs(freq_half - 36));
            stem(ax6, freq_half(idx_CH3), mag(idx_CH3), 'r', 'LineWidth', 1, 'MarkerSize', 6);
            text(ax6, 40, mag(idx_CH3)+180, '甲基 (δH 1.20)', 'FontSize', 6);
            [~, idx_CH2] = min(abs(freq_half - 108));
            stem(ax6, freq_half(idx_CH2), mag(idx_CH2), 'r', 'LineWidth', 1, 'MarkerSize', 6);
            text(ax6, 100, mag(idx_CH2)+1500, '亚甲基 (δH 3.60)', 'FontSize', 6);
            [~, idx_OH] = min(abs(freq_half - 150));
            stem(ax6, freq_half(idx_OH), mag(idx_OH), 'r', 'LineWidth', 1, 'MarkerSize', 6);
            text(ax6, 155, mag(idx_OH)+180, '羟基 (δH 5.0)', 'FontSize', 6);
            hold(ax6, 'off');
        
            % FID 3D动画演示按钮（底部预留按钮带，避免按钮盖住子图）
            obj.reserveBottomBand(0.11);
            uicontrol('Parent', obj.displayPanel, ...
                'Style', 'pushbutton', ...
                'String', '▶ 启动FID 3D动画演示', ...
                'Units', 'normalized', ...
                'Position', [0.2, 0.02, 0.6, 0.07], ...
                'FontSize', 12, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.8, 0.9, 1], ...
                'Callback', @(src,event) obj.launchFIDAnimation());
        
            sgtitle('步骤10：NMR自由感应衰减（FID）信号（30 MHz）', ...
                    'FontSize', 14, 'FontWeight', 'bold');
        end

        % 步骤11：完整总结
        function showSummary(obj)
            %SHOWSUMMARY 步骤11——完整总结（文本框显示，内容来自CSV第4列）
            %   使用可滚动、可选择复制的文本框，替代原来的图形文本。
            content = obj.operationInstructions{obj.currentStep};
            uicontrol('Parent', obj.displayPanel, ...
                'Style', 'edit', ...
                'Units', 'normalized', ...
                'Position', [0.03, 0.03, 0.94, 0.94], ...
                'String', content, ...
                'FontSize', 12, ...
                'FontName', 'Microsoft YaHei', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [1, 1, 1], ...
                'ForegroundColor', [0.1, 0.1, 0.1], ...
                'Max', 100, ...
                'Min', 0, ...
                'Enable', 'on', ...
                'SliderStep', [0.01, 0.1], ...
                'Callback', @(src,~) set(src, 'String', content));
        end

        function showLearningGuide(obj)
            %SHOWLEARNINGGUIDE 弹出学习指南窗口（内容从CSV加载）
            obj.showTextWindow('傅里叶变换学习指南', obj.learningGuideContent);
        end

        function showStepInstructions(obj)
            %SHOWSTEPINSTRUCTIONS 弹出当前步骤的详细讲解窗口
            %   内容来自 CSV 列4（详细讲解文本），即 operationInstructions 属性。
            if obj.currentStep >= 1 && obj.currentStep <= length(obj.operationInstructions)
                title = sprintf('步骤%d 详细讲解', obj.currentStep);
                obj.showTextWindow(title, obj.operationInstructions{obj.currentStep});
            end
        end

        function showTextWindow(obj, winTitle, content)
            %SHOWTEXTWINDOW 通用文本展示窗口
            %   创建一个可滚动的只读文本框显示多行文本，用户可选择和复制文字。
            fig = figure('Name', winTitle, ...
                'NumberTitle', 'off', ...
                'Position', [300, 200, 750, 520], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Color', [1, 1, 1]);

            hText = uicontrol('Parent', fig, ...
                'Style', 'edit', ...
                'Units', 'normalized', ...
                'Position', [0.02, 0.02, 0.96, 0.96], ...
                'String', content, ...
                'FontSize', 12, ...
                'FontName', 'Microsoft YaHei', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [1, 1, 1], ...
                'ForegroundColor', [0.1, 0.1, 0.1], ...
                'Max', 100, ...            % 允许多行
                'Min', 0, ...              % 允许多行
                'Enable', 'on', ...         % on=可选择复制
                'SliderStep', [0.01, 0.1], ...
                'Callback', @(src,~) set(src, 'String', content));  % Enter 恢复原文
        end

        function launchFourierSeriesAnimation(obj)
            %LAUNCHFOURIERSERIESANIMATION 启动傅里叶级数动画演示
            try
                animationObj = FourierSeriesAnimation();
                obj.currentAnimation = animationObj;
                set(animationObj.fig, 'Name', '傅里叶级数动画演示 - 标准方波分解');
            catch ME
                errordlg(['无法启动动画演示: ' ME.message], '动画错误');
            end
        end

        function launchEulerAnimation(obj)
            %LAUNCHEULERANIMATION 启动欧拉公式旋转圆动画演示
            %   使用 FourierCircleAnimation 展示复平面上旋转向量的叠加过程。
            try
                animationObj = FourierCircleAnimation();
                obj.currentAnimation = animationObj;
                set(animationObj.fig, 'Name', '傅里叶圆动画演示 - 旋转向量叠加与波形生成');
            catch ME
                errordlg(['无法启动动画演示: ' ME.message], '动画错误');
            end
        end

        function launchFIDAnimation(obj)
            %LAUNCHFIDANIMATION 启动FID信号与傅里叶变换的3D动画演示
            %   使用 FIDFourierTransformAnimation 展示磁化矢量演化和频谱累积。
            try
                animationObj = FIDFourierTransformAnimation();
                obj.currentAnimation = animationObj;
            catch ME
                errordlg(['无法启动FID动画演示: ' ME.message], '动画错误');
            end
        end

        function launchSamplingDemo(obj)
            %LAUNCHSAMPLINGDEMO 启动采样定理与混叠的交互演示窗口
            %   使用 SamplingAliasingDemo：拖动滑块改变 f0 与 fs，
            %   实时观察采样点、恢复信号、混叠频率与奈奎斯特临界条件。
            try
                demoObj = SamplingAliasingDemo();
                obj.currentAnimation = demoObj;   % 保持引用，避免被回收
            catch ME
                errordlg(['无法启动采样演示: ' ME.message], '演示错误');
            end
        end

        function updateExplanationText(obj)
            %UPDATEEXPLANATIONTEXT 更新控制面板中的操作说明文本
            %   显示 CSV 列3（操作说明），帮助用户了解当前步骤的观察要点。
            if obj.currentStep >= 1 && obj.currentStep <= length(obj.explanationContents)
                set(obj.explanationText, 'String', obj.explanationContents{obj.currentStep});
            end
        end

    end

end

% ====================== 局部辅助函数 ======================

function fields = splitQuoted(str, delimiter)
%SPLITQUOTED 按分隔符分割字符串，保留双引号内的内容完整
%   逗号在引号内时视为数据而非分隔符。最终去除字段的首尾引号。
    fields = {};
    if isempty(str), return; end
    current = '';
    inQuotes = false;

    for j = 1:numel(str)
        c = str(j);
        if c == '"'
            inQuotes = ~inQuotes;
            current(end+1) = c;  %#ok<AGROW>
        elseif c == delimiter && ~inQuotes
            fields{end+1} = trimUnquote(current);  %#ok<AGROW>
            current = '';
        else
            current(end+1) = c;  %#ok<AGROW>
        end
    end
    fields{end+1} = trimUnquote(current);
end

function s = trimUnquote(s)
%TRIMUNQUOTE 去除首尾空白和外围引号，还原转义引号
    s = strtrim(s);
    if numel(s) >= 2 && s(1) == '"' && s(end) == '"'
        s = s(2:end-1);
    end
    s = strrep(s, '""', '"');
end
