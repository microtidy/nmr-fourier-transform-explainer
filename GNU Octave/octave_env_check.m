function ok = octave_env_check()
%OCTAVE_ENV_CHECK GNU Octave 运行环境自检与配置
%   检查版本、绘图工具包、Signal 包、讲解文本，并做一次绘图自检。
  ok = true;
  baseDir = fileparts(mfilename('fullpath'));
  addpath(baseDir);
  fprintf('================ GNU Octave 运行环境自检 ================\n');
  fprintf('Octave 版本      : %s\n', version());
  fprintf('运行平台         : %s\n', computer());

  tk = available_graphics_toolkits();
  fprintf('可用绘图工具包   : %s\n', strjoin(tk, ', '));
  if any(strcmp(tk, 'qt'))
    try
      graphics_toolkit('qt');
      fprintf('已选择绘图工具包 : qt（推荐，支持中文与导出）\n');
    catch
    end
  end

  hasSignal = false;
  try
    pkg load signal;   %#ok<NASGU>
    hasSignal = true;
  catch
  end
  if hasSignal
    fprintf('Signal 包        : 已安装并加载\n');
  else
    fprintf('Signal 包        : 未安装 —— 使用内置替代函数 square/sawtooth/sinc/findpeaks\n');
  end

  fprintf('脚本目录         : %s\n', baseDir);
  if exist(fullfile(baseDir, 'display_texts.csv'), 'file')
    fprintf('讲解文本         : 找到 display_texts.csv\n');
  else
    fprintf('讲解文本         : 未找到（将使用内置简化文本）\n');
    ok = false;
  end

  try
    oct_setup_fonts();
    f = figure('visible', 'off');
    plot(1:5, 'linewidth', 2);
    title('环境自检：中文显示 傅里叶变换');
    png = fullfile(tempdir(), 'octave_env_check.png');
    print(f, png, '-dpng', '-r100');
    close(f);
    fprintf('绘图自检         : 通过（%s）\n', png);
  catch err
    fprintf('绘图自检         : 失败 - %s\n', err.message);
    ok = false;
  end
  fprintf('=========================================================\n');
end
