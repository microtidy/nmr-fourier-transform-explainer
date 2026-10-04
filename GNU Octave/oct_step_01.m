function oct_step_01(ctx)
%OCT_STEP_01 步骤1：时域与频域的基本概念（2×2）
  t = linspace(0, 5, 1000);

  ax1 = oct_axes(ctx.fig, oct_tile(ctx, 2, 2, 1));
  plot(ax1, t, sin(2*pi*t), 'b-', 'linewidth', 2);
  title(ax1, '时域：正弦波随时间变化'); xlabel(ax1, '时间 (s)'); ylabel(ax1, '振幅');
  xlim(ax1, [0 5]); ylim(ax1, [-1.5 1.5]); grid(ax1, 'on');

  ax2 = oct_axes(ctx.fig, oct_tile(ctx, 2, 2, 2));
  stem(ax2, 1, 1, 'r', 'linewidth', 2, 'markerfacecolor', 'r');
  title(ax2, '频域：单一频率成分'); xlabel(ax2, '频率 (Hz)'); ylabel(ax2, '振幅');
  xlim(ax2, [0 2]); ylim(ax2, [-0.1 1.2]); grid(ax2, 'on');

  ax3 = oct_axes(ctx.fig, oct_tile(ctx, 2, 2, 3));
  tm = linspace(0, 0.2, 2000);
  music = sin(2*pi*440*tm) + 0.5*sin(2*pi*880*tm) + 0.8*sin(2*pi*1320*tm);
  plot(ax3, tm, music, 'g-', 'linewidth', 1.5);
  title(ax3, '时域：复杂波形'); xlabel(ax3, '时间 (s)'); ylabel(ax3, '振幅');
  xlim(ax3, [0 0.02]); ylim(ax3, [-2 2]); grid(ax3, 'on');

  ax4 = oct_axes(ctx.fig, oct_tile(ctx, 2, 2, 4));
  stem(ax4, [0.44 0.88 1.32], [1 0.5 0.8], 'm', 'linewidth', 2, ...
       'markerfacecolor', 'm');
  title(ax4, '频域：复杂波形频谱'); xlabel(ax4, '频率 (kHz)'); ylabel(ax4, '振幅');
  xlim(ax4, [0 1.5]); ylim(ax4, [-0.1 1.2]); grid(ax4, 'on');

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤1：时域与频域的概念对比', 14);
end
