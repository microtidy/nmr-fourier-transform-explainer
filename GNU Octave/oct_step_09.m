function oct_step_09(ctx)
%OCT_STEP_09 步骤9：第一次傅里叶变换——射频脉冲
  g = @(idx) oct_tile(ctx, 3, 3, idx, 0.10, 0.06, 0.095);
  T0 = 2*pi; tau = T0/4;

  % 1. 无限长周期方波
  ax1 = oct_axes(ctx.fig, g(1));
  t1 = linspace(-2.5*T0, 2.5*T0, 3000);
  sw = zeros(size(t1));
  for i = -2:2
    sw(t1 >= i*T0-tau/2 & t1 <= i*T0+tau/2) = 1;
  end
  plot(ax1, t1/T0, sw, 'b-', 'linewidth', 1.4);
  title(ax1, '1. 无限长周期方波'); xlabel(ax1, '归一化时间 t/T'); ylabel(ax1, '振幅');
  grid(ax1, 'on'); xlim(ax1, [-2.5 2.5]); ylim(ax1, [-0.2 1.2]);

  % 2. 有限长脉冲序列（3 个周期）
  ax2 = oct_axes(ctx.fig, g(2));
  t2 = linspace(-3*T0, 3*T0, 3000);
  fin = zeros(size(t2));
  for i = -1:1
    fin(t2 >= i*T0-tau/2 & t2 <= i*T0+tau/2) = 1;
  end
  plot(ax2, t2/T0, fin, 'b-', 'linewidth', 1.4);
  title(ax2, '2. 有限长脉冲序列（3 个周期）'); xlabel(ax2, '归一化时间 t/T'); ylabel(ax2, '振幅');
  grid(ax2, 'on'); xlim(ax2, [-2 2]); ylim(ax2, [-0.2 1.2]);

  % 3. NMR 脉冲调制
  ax3 = oct_axes(ctx.fig, g(3));
  tau_us = 50; fc_MHz = 400;
  t_s = linspace(-0.5, 1.5, 40000);
  env = zeros(size(t_s));
  tau_s = tau_us*1e-6;
  env(t_s >= 0 & t_s <= tau_s) = 1;
  env(t_s >= 1 & t_s <= 1+tau_s) = 1;
  mod_sig = env .* cos(2*pi*fc_MHz*t_s*1e6);
  plot(ax3, t_s, mod_sig, 'b-', 'linewidth', 0.4); hold(ax3, 'on');
  plot(ax3, t_s, env, 'r-', 'linewidth', 1.2);
  plot(ax3, t_s, -env, 'r-', 'linewidth', 1.2); hold(ax3, 'off');
  title(ax3, '3. NMR 脉冲调制（时域）'); xlabel(ax3, '时间 (s)'); ylabel(ax3, '振幅');
  grid(ax3, 'on'); xlim(ax3, [-0.5 1.5]);

  % 4. 傅里叶级数双边谱
  ax4 = oct_axes(ctx.fig, g(4));
  nrange = -10:10;
  cn = zeros(size(nrange));
  for i = 1:numel(nrange)
    n = nrange(i);
    if n == 0
      cn(i) = tau/T0;
    else
      cn(i) = (tau/T0)*oct_sinc(n*tau/T0);
    end
  end
  stem(ax4, nrange, cn, 'b', 'linewidth', 1.2, 'markerfacecolor', 'b');
  title(ax4, '4. 傅里叶级数双边谱'); xlabel(ax4, '归一化频率 n'); ylabel(ax4, 'c_n');
  grid(ax4, 'on'); xlim(ax4, [-10.5 10.5]);

  % 5. 有限序列双边谱
  ax5 = oct_axes(ctx.fig, g(5));
  f5 = linspace(-5/T0, 5/T0, 1500);
  single = tau*oct_sinc(f5*tau);
  seq = single .* oct_sinc(f5*T0*3);
  plot(ax5, f5*T0, seq, 'b-', 'linewidth', 1.5);
  title(ax5, '5. 有限序列双边谱'); xlabel(ax5, '归一化频率 f·T'); ylabel(ax5, '幅度');
  grid(ax5, 'on'); xlim(ax5, [-5 5]);

  % 6. NMR 脉冲双边谱（τ=50μs，激发带宽≈20kHz）
  ax6 = oct_axes(ctx.fig, g(6));
  fk = linspace(-100, 100, 2000);
  ps = tau_us*oct_sinc(fk/1000*tau_us);
  plot(ax6, fk, ps, 'b-', 'linewidth', 1.5);
  title(ax6, '6. NMR 脉冲双边谱'); xlabel(ax6, '偏移频率 (kHz)'); ylabel(ax6, '幅度');
  grid(ax6, 'on'); xlim(ax6, [-100 100]);
  text(ax6, 0, max(ps)*1.05, '激发带宽 ≈ 1/τ = 20 kHz', ...
       'horizontalalignment', 'center');

  % 7. 傅里叶级数单边谱
  ax7 = oct_axes(ctx.fig, g(7));
  npos = 0:10;
  cs = zeros(size(npos));
  for i = 1:numel(npos)
    if npos(i) == 0
      cs(i) = tau/T0;
    else
      cs(i) = 2*(tau/T0)*oct_sinc(npos(i)*tau/T0);
    end
  end
  hold(ax7, 'on');
  stem(ax7, npos(1), cs(1), 'm', 'linewidth', 1.4, 'markerfacecolor', 'm');
  stem(ax7, npos(2:end), cs(2:end), 'b', 'linewidth', 1.2, 'markerfacecolor', 'b');
  hold(ax7, 'off');
  title(ax7, '7. 傅里叶级数单边谱'); xlabel(ax7, '谐波阶数 n'); ylabel(ax7, '系数');
  grid(ax7, 'on'); xlim(ax7, [-0.5 10.5]);

  % 8. 有限序列单边谱
  ax8 = oct_axes(ctx.fig, g(8));
  f8 = linspace(0, 5/T0, 800);
  sp = tau*oct_sinc(f8*tau) .* oct_sinc(f8*T0*3);
  sp(2:end) = 2*sp(2:end);
  plot(ax8, f8*T0, sp, 'b-', 'linewidth', 1.5);
  title(ax8, '8. 有限序列单边谱'); xlabel(ax8, '归一化频率 f·T'); ylabel(ax8, '幅度');
  grid(ax8, 'on'); xlim(ax8, [0 5]);

  % 9. NMR 脉冲单边谱
  ax9 = oct_axes(ctx.fig, g(9));
  fp = linspace(0, 100, 1500);
  psp = tau_us*oct_sinc(fp/1000*tau_us);
  psp(2:end) = 2*psp(2:end);
  plot(ax9, fp, psp, 'b-', 'linewidth', 1.5);
  title(ax9, '9. NMR 脉冲单边谱'); xlabel(ax9, '偏移频率 (kHz)'); ylabel(ax9, '幅度');
  grid(ax9, 'on'); xlim(ax9, [0 100]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤9：NMR脉冲调制 - 傅里叶变换的应用实例', 14);
end
