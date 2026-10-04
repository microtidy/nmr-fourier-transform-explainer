function oct_step_07(ctx)
%OCT_STEP_07 步骤7：傅里叶变换的运算原理（旋转探针）
  g = @(idx) oct_tile(ctx, 3, 3, idx, 0.10, 0.06, 0.095);
  t = linspace(-3, 3, 1200);
  tau = pi;                       % 脉冲宽度
  rect = double(abs(t) <= tau/2);

  % 1. 原始矩形脉冲
  ax1 = oct_axes(ctx.fig, g(1));
  plot(ax1, t, rect, 'b-', 'linewidth', 1.6);
  title(ax1, '1. 原始信号 f(t)（矩形脉冲）'); xlabel(ax1, '时间 t'); ylabel(ax1, '振幅');
  grid(ax1, 'on'); xlim(ax1, [-3 3]); ylim(ax1, [-0.2 1.3]);

  % 2. 核函数 e^{-iωt}（实部/虚部），ω=1
  ax2 = oct_axes(ctx.fig, g(2));
  w = 1;
  plot(ax2, t, cos(w*t), 'r-', 'linewidth', 1.3); hold(ax2, 'on');
  plot(ax2, t, -sin(w*t), 'g-', 'linewidth', 1.3); hold(ax2, 'off');
  title(ax2, '2. 核函数 e^{-iωt}（ω=1）'); xlabel(ax2, '时间 t'); ylabel(ax2, '振幅');
  legend(ax2, {'实部 cos', '虚部 -sin'}, 'location', 'southeast');
  grid(ax2, 'on'); xlim(ax2, [-3 3]); ylim(ax2, [-1.3 1.3]);

  % 3. 频谱 F(ω)（实部）
  ax3 = oct_axes(ctx.fig, g(3));
  ww = linspace(-5, 5, 1000);
  Fw = tau*oct_sinc(ww*tau/(2*pi));
  plot(ax3, ww, Fw, 'b-', 'linewidth', 1.8);
  title(ax3, '3. 频谱 F(ω)（实部）'); xlabel(ax3, '频率 ω'); ylabel(ax3, 'F(ω)');
  grid(ax3, 'on'); xlim(ax3, [-5 5]);

  % 4. 不匹配频率 ω=2（积分为零）
  ax4 = oct_axes(ctx.fig, g(4));
  w = 2;
  pr = rect.*cos(w*t); pi_ = -rect.*sin(w*t);
  plot(ax4, t, pr, 'r-', 'linewidth', 1.3); hold(ax4, 'on');
  plot(ax4, t, pi_, 'g-', 'linewidth', 1.3);
  plot(ax4, t, zeros(size(t)), 'k:'); hold(ax4, 'off');
  title(ax4, '4. 不匹配 ω=2 → 积分为 0'); xlabel(ax4, '时间 t'); ylabel(ax4, '振幅');
  legend(ax4, {'实部', '虚部'}, 'location', 'southeast');
  grid(ax4, 'on'); xlim(ax4, [-3 3]); ylim(ax4, [-1.2 1.2]);

  % 5. 3D 核函数螺旋（ω=1,2,3）
  ax5 = oct_axes(ctx.fig, g(5));
  hold(ax5, 'on'); grid(ax5, 'on');
  ws = [1 2 3];
  cs = [0.2 0.4 0.9; 0.85 0.2 0.2; 0.9 0.7 0.1];
  for i = 1:numel(ws)
    plot3(ax5, cos(ws(i)*t), sin(ws(i)*t), t, 'color', cs(i,:), 'linewidth', 1.6);
  end
  hold(ax5, 'off');
  title(ax5, '5. 核函数螺旋 e^{-iωt}（ω=1,2,3）');
  xlabel(ax5, '实部'); ylabel(ax5, '虚部'); zlabel(ax5, '时间 t');
  legend(ax5, {'ω=1', 'ω=2', 'ω=3'}, 'location', 'northeast');
  view(ax5, 30, 20);

  % 6. 半匹配 ω=1
  ax6 = oct_axes(ctx.fig, g(6));
  w = 1;
  pr = rect.*cos(w*t); pi_ = -rect.*sin(w*t);
  plot(ax6, t, pr, 'r-', 'linewidth', 1.3); hold(ax6, 'on');
  plot(ax6, t, pi_, 'g-', 'linewidth', 1.3);
  plot(ax6, t, zeros(size(t)), 'k:'); hold(ax6, 'off');
  title(ax6, '6. 正向变换 ω=1（半匹配）'); xlabel(ax6, '时间 t'); ylabel(ax6, '振幅');
  legend(ax6, {'实部', '虚部'}, 'location', 'southeast');
  grid(ax6, 'on'); xlim(ax6, [-3 3]); ylim(ax6, [-1.2 1.2]);

  % 7. 匹配 ω=0（直流）→ 积分 = 脉冲面积
  ax7 = oct_axes(ctx.fig, g(7));
  area(ax7, t, rect, 'facecolor', [0.6 0.6 1]); hold(ax7, 'on');
  plot(ax7, t, rect, 'b-', 'linewidth', 1.5); hold(ax7, 'off');
  title(ax7, '7. 匹配 ω=0：积分 = 脉冲面积 τ'); xlabel(ax7, '时间 t'); ylabel(ax7, '振幅');
  grid(ax7, 'on'); xlim(ax7, [-3 3]); ylim(ax7, [-0.2 1.3]);
  text(ax7, 0, 0.5, sprintf('积分 = %.2f', tau), 'horizontalalignment', 'center');

  % 8. 单边频谱
  ax8 = oct_axes(ctx.fig, g(8));
  wp = linspace(0, 5, 800);
  Fp = tau*oct_sinc(wp*tau/(2*pi));
  Fp(2:end) = 2*Fp(2:end);
  plot(ax8, wp, Fp, 'b-', 'linewidth', 1.8);
  title(ax8, '8. 单边谱 |F(ω)|'); xlabel(ax8, '频率 ω'); ylabel(ax8, '幅度');
  grid(ax8, 'on'); xlim(ax8, [0 5]);

  % 9. 反向合成
  ax9 = oct_axes(ctx.fig, g(9));
  rec = zeros(size(t));
  for k = 0:6
    w = k*2*pi/tau;
    cw = (tau/tau)*oct_sinc(w*tau/(2*pi));
    rec = rec + cw*cos(w*t);
  end
  rec = rec / max(abs(rec));
  plot(ax9, t, rec, 'b-', 'linewidth', 1.8); hold(ax9, 'on');
  plot(ax9, t, rect, 'r--', 'linewidth', 1.4); hold(ax9, 'off');
  title(ax9, '9. 反向合成（多频率分量叠加）'); xlabel(ax9, '时间 t'); ylabel(ax9, '振幅');
  legend(ax9, {'合成信号', '原始信号'}, 'location', 'southeast');
  grid(ax9, 'on'); xlim(ax9, [-3 3]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤7：傅里叶变换的运算原理 —— 旋转探针', 14);
end
