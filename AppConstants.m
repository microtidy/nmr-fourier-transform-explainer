classdef AppConstants
    %APPCONSTANTS 傅里叶变换讲解器全局常量
    %   集中管理所有颜色、尺寸和动画参数，避免魔术数字散布各处。
    %
    %   使用方法:
    %     bgColor = AppConstants.COLOR_BG_MAIN;
    %     figSize = AppConstants.FIG_SIZE_MAIN;

    properties (Constant)
        % ===== 颜色方案 =====
        COLOR_BG_MAIN       = [0.95, 0.95, 0.95]   % 主背景色（浅灰）
        COLOR_BG_CONTROL    = [0.9, 0.9, 0.9]       % 控制面板背景
        COLOR_BG_CONTROL2   = [0.9, 0.95, 1]        % 控制面板背景（蓝色调）
        COLOR_BG_DISPLAY    = [1, 1, 1]              % 显示面板背景（白色）
        COLOR_BG_SUMMARY    = [0.95, 0.95, 0.95]    % 汇总面板背景
        COLOR_TEXT_BG       = [0.95, 0.95, 0.95]    % 文本框背景

        % 按钮颜色
        COLOR_BTN_START     = [0.7, 0.9, 0.7]       % 开始按钮（绿色）
        COLOR_BTN_PAUSE     = [1, 0.95, 0.8]        % 暂停按钮（橙色）
        COLOR_BTN_RESET     = [1, 0.8, 0.8]         % 重置按钮（红色）
        COLOR_BTN_GUIDE     = [0.8, 0.9, 1]         % 学习指南按钮（蓝色）
        COLOR_BTN_ANIMATION = [0.8, 0.9, 1]         % 动画启动按钮（蓝色）

        % 绘图颜色
        COLOR_WAVEFORM      = [0, 0, 1]             % 波形默认蓝色
        COLOR_REFERENCE     = [1, 0, 0]             % 参考线红色

        % ===== 窗口尺寸 =====
        FIG_WIDTH_MAIN      = 1200                   % 主窗口宽度
        FIG_HEIGHT_MAIN     = 750                    % 主窗口高度
        FIG_WIDTH_ANIM      = 1200                   % 动画窗口宽度
        FIG_HEIGHT_ANIM     = 800                    % 动画窗口高度
        FIG_WIDTH_CIRCLE    = 1400                   % 圆动画窗口宽度
        FIG_HEIGHT_CIRCLE   = 800                    % 圆动画窗口高度

        % ===== 面板比例 =====
        CONTROL_PANEL_WIDTH  = 0.28   % 控制面板占总宽度的比例
        DISPLAY_PANEL_LEFT   = 0.30   % 显示面板左边界
        DISPLAY_PANEL_BOTTOM = 0.15   % 显示面板下边界
        DISPLAY_PANEL_WIDTH  = 0.69   % 显示面板宽度
        DISPLAY_PANEL_HEIGHT = 0.84   % 显示面板高度
        SUMMARY_PANEL_HEIGHT = 0.13   % 汇总面板高度

        % ===== 字体大小 =====
        FONT_SIZE_TITLE     = 12   % 面板标题
        FONT_SIZE_BUTTON    = 10   % 按钮文字
        FONT_SIZE_TEXT      = 10   % 正文
        FONT_SIZE_SMALL     = 8    % 小号标注

        % ===== 动画参数 =====
        ANIM_DEFAULT_FRAMES   = 200    % 默认总帧数
        ANIM_DEFAULT_SPEED    = 3      % 默认速度 (1-10)
        ANIM_DEFAULT_PERIOD_S = 0.03   % 默认帧间隔 (秒)
    end

    methods (Static)
        function colors = harmonicColors(n)
            %HARMONICCOLORS 生成 n 个谐波的颜色列表
            %   使用 lines 色彩映射，确保相邻谐波颜色可区分。
            colors = lines(n);
        end
    end
end
