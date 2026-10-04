function octave_selftest()
%OCTAVE_SELFTEST 无界面自检：渲染全部步骤与演示到 PNG，便于调试
%   运行后在 selftest_out 目录查看输出图片。
  baseDir = fileparts(mfilename('fullpath'));
  addpath(baseDir);
  oct_setup_fonts();
  tk = available_graphics_toolkits();
  if any(strcmp(tk, 'qt'))
    try
      graphics_toolkit('qt');
    catch
    end
  end
  set(0, 'defaultfigurevisible', 'off');

  outdir = fullfile(baseDir, 'selftest_out');
  if ~exist(outdir, 'dir')
    mkdir(outdir);
  end
  fprintf('开始自检，输出目录：%s\n', outdir);
  fails = 0;

  fig = fourier_explainer_octave();
  S = getappdata(fig, 'ftstate');
  n = numel(S.stepTitles);
  for k = 1:n
    try
      oct_show_step(fig, k);
      print(fig, fullfile(outdir, sprintf('step_%02d.png', k)), '-dpng', '-r110');
      fprintf('  步骤 %2d : OK\n', k);
    catch err
      fails = fails + 1;
      fprintf('  步骤 %2d : 失败 - %s\n', k, err.message);
    end
  end
  close(fig);

  % 采样交互演示
  try
    d = sampling_aliasing_demo_octave();
    set(getappdata(d, 'demostate').slF0, 'value', 3);
    set(getappdata(d, 'demostate').slFs, 'value', 4);
    oct_demo_update(d);
    print(d, fullfile(outdir, 'demo_aliased.png'), '-dpng', '-r110');
    close(d);
    fprintf('  采样交互演示 : OK\n');
  catch err
    fails = fails + 1;
    fprintf('  采样交互演示 : 失败 - %s\n', err.message);
  end

  % 动画（绘制中间一帧）
  anims = {@fourier_series_anim_octave, 'anim_series'; ...
           @fourier_circle_anim_octave, 'anim_circle'; ...
           @fid_anim_octave,           'anim_fid'};
  for i = 1:size(anims, 1)
    try
      a = anims{i,1}();
      key = ['anim_' anims{i,2}(6:end)];
      st = getappdata(a, key);
      st.frame = round(st.maxFrame/2);
      setappdata(a, key, st);
      oct_anim_draw(a, anims{i,2}(6:end));
      print(a, fullfile(outdir, [anims{i,2} '.png']), '-dpng', '-r110');
      close(a);
      fprintf('  %s : OK\n', anims{i,2});
    catch err
      fails = fails + 1;
      fprintf('  %s : 失败 - %s\n', anims{i,2}, err.message);
    end
  end

  fprintf('自检完成：失败项 %d 个。\n', fails);
end
