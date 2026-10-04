function fig = run_fourier_explainer_octave()
%RUN_FOURIER_EXPLAINER_OCTAVE 启动傅里叶变换原理讲解器（GNU Octave 版）
%   与 MATLAB 版 runFourierTransformExplainer 对应。
  baseDir = fileparts(mfilename('fullpath'));
  addpath(baseDir);
  fprintf('正在启动傅里叶变换原理讲解器（GNU Octave 版）...\n');
  fprintf('使用方法：点击左侧步骤按钮选择讲解步骤；\n');
  fprintf('           拖动中间分隔条可调整左右宽度；\n');
  fprintf('           把鼠标移到子图上，可用图例/坐标轴工具查看细节。\n');
  fig = fourier_explainer_octave();
end
