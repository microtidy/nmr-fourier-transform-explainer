function oct_step_02(ctx)
%OCT_STEP_02 步骤2：傅里叶级数——正弦波叠加逼近方波
  t = linspace(-pi/2, 7*pi/2, 1500);
  sq = sign(sin(t));
  fund = (4/pi)*sin(t);
  h3 = (4/(3*pi))*sin(3*t);
  h5 = (4/(5*pi))*sin(5*t);

  ax1 = oct_axes(ctx.fig, oct_tile(ctx, 2, 3, 1, 0.11, 0.20, 0.12));
  plot(ax1, t, fund, 'b-', 'linewidth', 1.8); hold(ax1, 'on');
  plot(ax1, t, sq,   'r--', 'linewidth', 1.2); hold(ax1, 'off');
  title(ax1, '1. 基波 (4/π)sin(t)'); xlabel(ax1, '时间 (弧度)'); ylabel(ax1, '振幅');
  legend(ax1, {'基波', '标准方波'}, 'location', 'southeast');
  grid(ax1, 'on'); xlim(ax1, [-pi/2 3*pi/2]); ylim(ax1, [-2.0 1.7]);

  ax2 = oct_axes(ctx.fig, oct_tile(ctx, 2, 3, 2, 0.11, 0.20, 0.12));
  plot(ax2, t, fund, 'b-', 'linewidth', 1.3); hold(ax2, 'on');
  plot(ax2, t, h3,   'r-', 'linewidth', 1.3);
  plot(ax2, t, fund+h3, 'k-', 'linewidth', 2);
  plot(ax2, t, sq, 'r--', 'linewidth', 1.2); hold(ax2, 'off');
  title(ax2, '2. 基波 + 3 次谐波'); xlabel(ax2, '时间 (弧度)'); ylabel(ax2, '振幅');
  legend(ax2, {'基波', '3次谐波', '叠加总和', '标准方波'}, 'location', 'southeast');
  grid(ax2, 'on'); xlim(ax2, [-pi/2 3*pi/2]); ylim(ax2, [-2.2 1.7]);

  ax3 = oct_axes(ctx.fig, oct_tile(ctx, 2, 3, 3, 0.11, 0.20, 0.12));
  plot(ax3, t, fund, 'b-', 'linewidth', 1.1); hold(ax3, 'on');
  plot(ax3, t, h3,   'r-', 'linewidth', 1.1);
  plot(ax3, t, h5,   'g-', 'linewidth', 1.1);
  plot(ax3, t, fund+h3+h5, 'k-', 'linewidth', 2);
  plot(ax3, t, sq, 'r--', 'linewidth', 1.2); hold(ax3, 'off');
  title(ax3, '3. 前 3 个奇次谐波'); xlabel(ax3, '时间 (弧度)'); ylabel(ax3, '振幅');
  legend(ax3, {'基波', '3次', '5次', '叠加', '标准方波'}, 'location', 'southeast');
  grid(ax3, 'on'); xlim(ax3, [-pi/2 3*pi/2]); ylim(ax3, [-2.2 1.7]);

  % 3D：各次谐波沿阶数堆叠 + 频谱
  ax4 = oct_axes(ctx.fig, oct_tile_span(ctx, 2, 3, [4 5 6], 0.11, 0.20, 0.12));
  numF = 9;
  col = oct_parula(numF);
  hold(ax4, 'on'); grid(ax4, 'on');
  for k = 1:numF
    if mod(k,2) == 1
      hk = (4/(pi*k))*sin(k*t);
      plot3(ax4, t, k*ones(size(t)), hk, 'color', col(k,:), 'linewidth', 1.3);
    else
      plot3(ax4, t, k*ones(size(t)), zeros(size(t)), 'color', [0.7 0.7 0.7]);
    end
  end
  ssum = zeros(size(t));
  for k = 1:2:9
    ssum = ssum + (4/(pi*k))*sin(k*t);
  end
  plot3(ax4, t, numF*ones(size(t)), ssum, 'k-', 'linewidth', 2.2);
  plot3(ax4, t, (numF+0.6)*ones(size(t)), sq, 'r:', 'linewidth', 1.5);
  hold(ax4, 'off');
  xlabel(ax4, '时间'); ylabel(ax4, '谐波阶数 n'); zlabel(ax4, '振幅');
  title(ax4, '标准方波的傅里叶分解（3D 视图）');
  view(ax4, 45, 22); xlim(ax4, [-pi/2 3*pi/2]); ylim(ax4, [0.5 numF+1]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.945, d(3), d(4)*0.05], ...
              '步骤2：傅里叶级数 - 正弦波叠加逼近矩形波', 14);

  % 底部动画按钮
  yb = d(2) + 0.02*d(4);
  uicontrol('Parent', ctx.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [d(1)+0.30*d(3), yb, 0.17*d(3), 0.055*d(4)], ...
      'String', '级数分解动画', 'FontSize', 10, 'Tag', 'octstep', ...
      'BackgroundColor', [0.8 0.9 1], ...
      'Callback', @(~,~) fourier_series_anim_octave());
  uicontrol('Parent', ctx.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [d(1)+0.53*d(3), yb, 0.17*d(3), 0.055*d(4)], ...
      'String', '旋转圆动画', 'FontSize', 10, 'Tag', 'octstep', ...
      'BackgroundColor', [0.8 1 0.8], ...
      'Callback', @(~,~) fourier_circle_anim_octave());
end
