function oct_step_06(ctx)
%OCT_STEP_06 步骤6：傅里叶级数与傅里叶变换的对比
  g = @(idx) oct_tile(ctx, 3, 3, idx, 0.10, 0.06, 0.095);

  % 1. 周期方波
  ax1 = oct_axes(ctx.fig, g(1));
  tt = linspace(-2, 2, 2000);
  sq = sign(sin(pi*tt));
  plot(ax1, tt, sq, 'b-', 'linewidth', 1.5);
  title(ax1, '1. 周期方波（周期 T）'); xlabel(ax1, '归一化时间 t/T'); ylabel(ax1, '振幅');
  grid(ax1, 'on'); xlim(ax1, [-2 2]); ylim(ax1, [-1.4 1.4]);

  % 2. 单个矩形脉冲（非周期）
  ax2 = oct_axes(ctx.fig, g(2));
  tau = 1;
  rect = double(abs(tt) <= tau/2);
  plot(ax2, tt, rect, 'b-', 'linewidth', 1.5);
  title(ax2, '2. 单个矩形脉冲（非周期）'); xlabel(ax2, '时间 t'); ylabel(ax2, '振幅');
  grid(ax2, 'on'); xlim(ax2, [-2 2]); ylim(ax2, [-0.2 1.3]);

  % 3. 高斯信号
  ax3 = oct_axes(ctx.fig, g(3));
  sig = 0.5;
  tt3 = linspace(-1.5, 1.5, 800);
  gs = exp(-tt3.^2/(2*sig^2));
  plot(ax3, tt3, gs, 'b-', 'linewidth', 1.8);
  title(ax3, '3. 时域：高斯信号'); xlabel(ax3, '时间 t'); ylabel(ax3, '振幅');
  grid(ax3, 'on'); xlim(ax3, [-1.5 1.5]);

  % 4. 傅里叶级数离散谱
  ax4 = oct_axes(ctx.fig, g(4));
  nn = -10:10;
  cn = (tau/2)*oct_sinc(nn*tau/2);
  stem(ax4, nn, cn, 'b', 'linewidth', 1.2, 'markerfacecolor', 'b');
  title(ax4, '4. 频域：傅里叶级数（离散）'); xlabel(ax4, '频率 n'); ylabel(ax4, 'c_n');
  grid(ax4, 'on'); xlim(ax4, [-10.5 10.5]);

  % 5. 傅里叶变换连续谱
  ax5 = oct_axes(ctx.fig, g(5));
  ff = linspace(-10, 10, 1000);
  Fw = tau*oct_sinc(ff*tau/(2*pi));
  plot(ax5, ff, Fw, 'b-', 'linewidth', 1.8);
  title(ax5, '5. 频域：傅里叶变换（连续）'); xlabel(ax5, '频率 f'); ylabel(ax5, 'F(f)');
  grid(ax5, 'on'); xlim(ax5, [-10 10]);

  % 6. 高斯函数的傅里叶变换（仍是高斯）
  ax6 = oct_axes(ctx.fig, g(6));
  f6 = linspace(-4, 4, 800);
  G = exp(-2*(pi*sig*f6).^2);
  plot(ax6, f6, G, 'b-', 'linewidth', 1.8);
  title(ax6, '6. 高斯函数的傅里叶变换'); xlabel(ax6, '频率 f'); ylabel(ax6, 'F(f)');
  grid(ax6, 'on'); xlim(ax6, [-4 4]);

  % 7. 傅里叶级数单边谱
  ax7 = oct_axes(ctx.fig, g(7));
  np = 0:10;
  cs = zeros(size(np));
  for i = 1:numel(np)
    if np(i) == 0
      cs(i) = tau/2;
    else
      cs(i) = 2*(tau/2)*oct_sinc(np(i)*tau/2);
    end
  end
  hold(ax7, 'on');
  for i = 1:numel(np)
    if np(i) == 0
      stem(ax7, np(i), cs(i), 'm', 'linewidth', 1.4, 'markerfacecolor', 'm');
    else
      stem(ax7, np(i), cs(i), 'b', 'linewidth', 1.2, 'markerfacecolor', 'b');
    end
  end
  hold(ax7, 'off');
  title(ax7, '7. 傅里叶级数单边谱'); xlabel(ax7, '谐波阶数 n'); ylabel(ax7, '系数');
  legend(ax7, {'直流', 'f>0 (加倍)'}, 'location', 'northeast');
  grid(ax7, 'on'); xlim(ax7, [-0.5 10.5]);

  % 8. 傅里叶变换单边谱
  ax8 = oct_axes(ctx.fig, g(8));
  fp = linspace(0, 10, 800);
  Fp = tau*oct_sinc(fp*tau/(2*pi));
  Fp(2:end) = 2*Fp(2:end);
  plot(ax8, fp, Fp, 'b-', 'linewidth', 1.8);
  title(ax8, '8. 傅里叶变换单边谱'); xlabel(ax8, '频率 f'); ylabel(ax8, 'F(f)');
  grid(ax8, 'on'); xlim(ax8, [0 10]);

  % 9. 高斯函数单边谱
  ax9 = oct_axes(ctx.fig, g(9));
  f9 = linspace(0, 4, 800);
  G9 = exp(-2*(pi*sig*f9).^2);
  G9(2:end) = 2*G9(2:end);
  plot(ax9, f9, G9, 'b-', 'linewidth', 1.8);
  title(ax9, '9. 高斯函数单边谱'); xlabel(ax9, '频率 f'); ylabel(ax9, 'F(f)');
  grid(ax9, 'on'); xlim(ax9, [0 4]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤6：傅里叶级数与傅里叶变换原理对比（含单边谱）', 14);
end
