classdef BaseAnimation < handle
    %BASEANIMATION 动画演示抽象基类
    %   封装MATLAB timer动画的公共逻辑：定时器生命周期管理、动画状态控制、
    %   按钮状态切换、窗口关闭处理。子类只需实现 initGraphics、
    %   updateAnimationFrame 和 initializeAnimationData 三个方法。

    properties (GetAccess = public, SetAccess = protected)
        % ---- GUI 组件（fig 对外公开可读，便于宿主设置标题等） ----
        fig
    end

    properties (Access = protected)
        % ---- GUI 组件 ----
        mainPanel
        controlPanel

        % ---- 动画状态 ----
        isAnimating     (1,1) logical = false
        animationSpeed  (1,1) double  = 0.03
        animationTimer                  % timer 对象
        currentFrame    (1,1) double  = 1
        totalFrames     (1,1) double  = 200

        % ---- 图形句柄容器 ----
        animationObjects                % struct，存储所有动态更新的图形句柄
    end

    methods (Abstract, Access = protected)
        % 子类必须实现的三个核心方法

        createGUI(obj)
        %CREATEGUI 创建图形用户界面
        %   子类负责创建 fig、mainPanel、controlPanel 以及所有 UI 控件。

        initGraphics(obj)
        %INITGRAPHICS 初始化所有图形元素
        %   创建动画中需要动态更新的线条、标记等图形对象，
        %   并存入 animationObjects 结构体。

        initializeAnimationData(obj)
        %INITIALIZEANIMATIONDATA 初始化/重置动画数据
        %   每次动画开始前或重置时调用，负责清空轨迹缓存等。

        updateAnimationFrame(obj)
        %UPDATEANIMATIONFRAME 更新一帧动画
        %   由基类的 updateAnimation 回调调用。子类在此绘制当前帧。
    end

    methods (Sealed)
        % ---- 封装的定时器管理（子类不可覆盖） ----

        function startAnimation(obj)
            %STARTANIMATION 启动或恢复动画播放
            if obj.isAnimating
                return;
            end

            if obj.currentFrame > obj.totalFrames
                obj.currentFrame = 1;
            end

            if isempty(obj.animationTimer) || ~isvalid(obj.animationTimer)
                obj.isAnimating = true;
                obj.createAndStartTimer();
                obj.onAnimationStarted();
            end
        end

        function stopAnimation(obj)
            %STOPANIMATION 停止动画并销毁定时器
            obj.destroyTimer();
            obj.isAnimating = false;
            obj.onAnimationStopped();
        end

        function toggleAnimation(obj)
            %TOGGLEANIMATION 暂停/继续动画
            if obj.isAnimating
                obj.stopAnimation();
            else
                if obj.currentFrame > obj.totalFrames
                    obj.currentFrame = 1;
                end
                obj.isAnimating = true;
                obj.createAndStartTimer();
                obj.onAnimationStarted();
            end
        end

        function resetAnimation(obj)
            %RESETANIMATION 重置动画到初始状态
            obj.stopAnimation();
            obj.currentFrame = 1;
            obj.initializeAnimationData();
            obj.initGraphics();
        end

        function updateAnimationSpeed(obj, speed)
            %UPDATEANIMATIONSPEED 根据滑块值更新动画速度
            if isempty(speed) || ~isnumeric(speed) || speed <= 0
                speed = 3;
            end
            obj.animationSpeed = 0.1 / max(speed, 0.1);
            if obj.isAnimating
                wasAnimating = true;
                obj.stopAnimation();
                obj.isAnimating = true;
                obj.createAndStartTimer();
            end
        end

        function closeWindow(obj)
            %CLOSEWINDOW 安全关闭动画窗口
            obj.stopAnimation();
            if ~isempty(obj.fig) && ishandle(obj.fig)
                delete(obj.fig);
            end
        end
    end

    methods (Access = protected)
        % ---- 子类可覆盖的回调钩子 ----

        function onAnimationStarted(obj)
            %ONANIMATIONSTARTED 动画启动后的回调（子类可覆盖以更新按钮文本）
        end

        function onAnimationStopped(obj)
            %ONANIMATIONSTOPPED 动画停止后的回调（子类可覆盖以更新按钮文本）
        end

        % ---- 辅助函数 ----

        function handle = safeGetHandle(obj, fieldName, index)
            %SAFEGETHANDLE 安全获取 animationObjects 中的图形句柄
            %   验证字段存在、索引有效、句柄有效。无效时返回空。
            handle = [];
            if ~isfield(obj.animationObjects, fieldName)
                return;
            end
            items = obj.animationObjects.(fieldName);
            if ~iscell(items)
                handle = items;
                return;
            end
            if index > length(items) || isempty(items{index})
                return;
            end
            candidate = items{index};
            if ishandle(candidate)
                handle = candidate;
            end
        end

        function safeSet(obj, handle, varargin)
            %SAFESET 安全调用 set，仅在句柄有效时执行
            if ~isempty(handle) && ishandle(handle)
                set(handle, varargin{:});
            end
        end

        function updateButtonText(obj, oldText, newText, enableState)
            %UPDATEBUTTONTEXT 查找并更新指定文本的按钮
            buttons = findobj(obj.controlPanel, 'Style', 'pushbutton', ...
                'String', oldText);
            for i = 1:length(buttons)
                set(buttons(i), 'String', newText, 'Enable', enableState);
            end
        end
    end

    methods (Access = private)
        % ---- 内部定时器管理 ----

        function createAndStartTimer(obj)
            %CREATEANDSTARTTIMER 创建并启动MATLAB定时器
            obj.destroyTimer();

            if isempty(obj.animationSpeed) || ~isnumeric(obj.animationSpeed) ...
                    || obj.animationSpeed <= 0
                obj.animationSpeed = 0.03;
            end

            try
                obj.animationTimer = timer(...
                    'ExecutionMode', 'fixedRate', ...
                    'Period', obj.animationSpeed, ...
                    'TimerFcn', @(~,~) obj.updateAnimation(), ...
                    'StopFcn', @(~,~) obj.onTimerStopped());
                start(obj.animationTimer);
            catch ME
                obj.isAnimating = false;
                errordlg(['无法启动动画: ' ME.message], '动画错误');
            end
        end

        function destroyTimer(obj)
            %DESTROYTIMER 停止并删除定时器
            if ~isempty(obj.animationTimer) && isvalid(obj.animationTimer)
                stop(obj.animationTimer);
                delete(obj.animationTimer);
            end
            obj.animationTimer = [];
        end

        function updateAnimation(obj)
            %UPDATEANIMATION 定时器回调：帧更新入口
            if ~obj.isAnimating || obj.currentFrame > obj.totalFrames
                obj.stopAnimation();
                return;
            end

            try
                obj.updateAnimationFrame();
                obj.currentFrame = obj.currentFrame + 1;
                drawnow limitrate;
            catch ME
                warning('BaseAnimation:FrameError', ...
                    '动画帧更新失败 (帧 %d): %s', obj.currentFrame, ME.message);
                obj.stopAnimation();
            end
        end

        function onTimerStopped(obj)
            %ONTIMERSTOPPED 定时器正常结束回调
            obj.isAnimating = false;
            obj.onAnimationStopped();
        end
    end
end
