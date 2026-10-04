function fig = fourier_explainer_octave()
%FOURIER_EXPLAINER_OCTAVE 傅里叶变换原理讲解器（GNU Octave 版）
%   与 MATLAB 版功能对应：11 个讲解步骤、学习指南、步骤说明、
%   核心要点汇总、可拖动分隔条、采样混叠交互演示与 3 段动画。
%
%   用法：在 GNU Octave 中先 cd 到本目录，然后运行
%         fourier_explainer_octave
%       或直接运行 run_fourier_explainer_octave

  baseDir = fileparts(mfilename('fullpath'));
  addpath(baseDir);
  oct_setup_fonts();

  S = oct_load_texts(baseDir);
  S.baseDir = baseDir;
  S.currentStep = 1;
  S.controlFrac = 0.24;
  S.fontName = 'Microsoft YaHei';

  % ---------- 主窗口 ----------
  scr = get(0, 'screensize');
  figW = min(1320, round(scr(3) * 0.92));
  figH = min(840,  round(scr(4) * 0.90));
  figW = max(figW, 1000);
  figH = max(figH, 660);
  fX = 40;    % 固定放在屏幕左上方，避免高 DPI 缩放下窗口跑到屏幕外
  fY = 40;

  fig = figure('Name', 'NMR傅里叶变换原理讲解器（Octave版）', ...
               'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
               'Position', [fX, fY, figW, figH], ...
               'Color', [0.95 0.95 0.95], 'Resize', 'on');
  try
    movegui(fig, 'center');   % 确保窗口位于屏幕可见区域
  catch
  end
  try
    mp = get(0, 'monitorpositions');   % 依据显示器可用区域放置窗口
    if ~isempty(mp) && size(mp, 2) >= 4
      set(fig, 'position', mp(1, 1:4));
    end
  catch
  end
  S.fig = fig;

  H = struct();
  H.ctrlPanel = uipanel('Parent', fig, 'Units', 'normalized', ...
      'Title', '控制面板', 'FontSize', 12, 'BackgroundColor', [0.9 0.9 0.9]);
  H.splitter = uicontrol('Parent', fig, 'Style', 'text', 'Units', 'normalized', ...
      'String', '', 'BackgroundColor', [0.72 0.76 0.86], 'Enable', 'on', ...
      'TooltipString', '拖动可调整左右宽度比例', ...
      'ButtonDownFcn', @(~,~) oct_start_split_drag(fig));
  % 说明：Octave 的 uipanel 是覆盖在画布之上的控件，会挡住其中的坐标轴，
  %       因此显示区不放置 uipanel，绘图坐标轴直接绘制在 figure 画布上。
  H.dispLabel = uicontrol('Parent', fig, 'Style', 'text', 'String', '原理展示', ...
      'Units', 'normalized', 'HorizontalAlignment', 'left', 'FontSize', 11, ...
      'FontWeight', 'bold', 'BackgroundColor', [0.95 0.95 0.95]);
  H.sumPanel = uipanel('Parent', fig, 'Units', 'normalized', ...
      'Title', '核心要点汇总', 'FontSize', 11, 'BackgroundColor', [0.95 0.95 0.95]);

  H.summaryText = uicontrol('Parent', H.sumPanel, 'Style', 'edit', ...
      'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
      'FontSize', 9, 'BackgroundColor', [1 1 1], 'ForegroundColor', [0.1 0.1 0.1], ...
      'HorizontalAlignment', 'left', 'Max', 100, 'Min', 0, 'Enable', 'on', ...
      'String', '选择步骤查看核心要点汇总...');

  % ---------- 控制面板内的按钮与文本框 ----------
  n = numel(S.stepTitles);
  btnTop = 0.955; btnBottom = 0.545; btnGap = 0.004;
  btnH = (btnTop - btnBottom - (n-1)*btnGap) / n;
  H.stepButtons = zeros(1, n);
  for i = 1:n
    posY = btnTop - i*btnH - (i-1)*btnGap;
    H.stepButtons(i) = uicontrol('Parent', H.ctrlPanel, 'Style', 'pushbutton', ...
        'Units', 'normalized', 'Position', [0.03, posY, 0.94, btnH], ...
        'String', sprintf('%d: %s', i, S.stepTitles{i}), 'FontSize', 9, ...
        'Callback', @(~,~) oct_show_step(fig, i));
  end

  H.explanationText = uicontrol('Parent', H.ctrlPanel, 'Style', 'edit', ...
      'Units', 'normalized', 'Position', [0.03 0.02 0.94 0.465], ...
      'String', '选择步骤查看详细讲解', 'FontSize', 9, ...
      'BackgroundColor', [0.95 0.95 0.95], 'HorizontalAlignment', 'left', ...
      'Max', 10, 'Min', 0, 'Enable', 'on');

  uicontrol('Parent', H.ctrlPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [0.03 0.495 0.46 0.042], 'String', '学习指南', 'FontSize', 9, ...
      'BackgroundColor', [0.8 0.9 1], 'Callback', @(~,~) oct_show_learning_guide(fig));
  uicontrol('Parent', H.ctrlPanel, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [0.51 0.495 0.46 0.042], 'String', '步骤说明', 'FontSize', 9, ...
      'BackgroundColor', [0.9 1 0.9], 'Callback', @(~,~) oct_show_step_instructions(fig));

  S.handles = H;
  setappdata(fig, 'ftstate', S);

  set(fig, 'SizeChangedFcn', @(~,~) oct_on_resize(fig));
  oct_apply_layout(fig);
  oct_show_step(fig, 1);
end


function S = oct_load_texts(baseDir)
%OCT_LOAD_TEXTS 读取 display_texts.csv；缺失时使用内置简化文本
  csvPath = fullfile(baseDir, 'display_texts.csv');
  S = struct();
  if ~exist(csvPath, 'file')
    [S.stepTitles, S.explanationContents, S.operationInstructions, ...
     S.summaryContents, S.learningGuideContent] = oct_builtin_texts();
    return;
  end
  try
    data = oct_readcsv(csvPath);
    col1 = data(2:end, 1);
    isLG = strcmp(col1, 'LG');
    isStep = ~isLG;
    idxStep = find(isStep) + 1;
    stepData = data(idxStep, :);
    nS = size(stepData, 1);
    S.stepTitles = cell(nS,1);
    S.explanationContents = cell(nS,1);
    S.operationInstructions = cell(nS,1);
    S.summaryContents = cell(nS,1);
    nl = sprintf('\n');
    for i = 1:nS
      S.stepTitles{i}            = stepData{i,2};
      S.explanationContents{i}   = strrep(stepData{i,3}, '\n', nl);
      S.operationInstructions{i} = strrep(stepData{i,4}, '\n', nl);
      S.summaryContents{i}       = strrep(stepData{i,5}, '\n', nl);
    end
    if any(isLG)
      lg = data(find(isLG) + 1, :);
      S.learningGuideContent = strrep(lg{1,3}, '\n', nl);
    else
      S.learningGuideContent = '学习指南内容未找到。';
    end
  catch err
    fprintf('读取 display_texts.csv 失败（%s），使用内置文本。\n', err.message);
    [S.stepTitles, S.explanationContents, S.operationInstructions, ...
     S.summaryContents, S.learningGuideContent] = oct_builtin_texts();
  end
end


function [titles, ops, details, sums, guide] = oct_builtin_texts()
%OCT_BUILTIN_TEXTS CSV 不可用时的后备文本
  titles = {
    '时域与频域的基本概念';
    '傅里叶级数：正弦波叠加逼近方波';
    '谐波叠加的收敛过程与吉布斯现象';
    '信号的频率、振幅、相位';
    '欧拉公式与旋转向量';
    '复指数形式与正负频率';
    '傅里叶变换的运算原理';
    '采样定理——完全采样与混叠';
    '第一次傅里叶变换——射频脉冲';
    '第二次傅里叶变换——FID信号';
    '总结——傅里叶变换的意义'
  };
  n = numel(titles);
  ops = cell(n,1); details = cell(n,1); sums = cell(n,1);
  for i = 1:n
    ops{i} = sprintf('步骤%d\n\n操作说明未能从 CSV 加载。', i);
    details{i} = sprintf('步骤%d\n\n详细讲解未能从 CSV 加载。', i);
    sums{i} = sprintf('步骤%d\n\n汇总文本未能从 CSV 加载。', i);
  end
  guide = '学习指南内容未加载。请检查 display_texts.csv 文件。';
end
