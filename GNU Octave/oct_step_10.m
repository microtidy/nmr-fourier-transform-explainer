function oct_step_10(ctx)
%OCT_STEP_10 步骤10：第二次傅里叶变换——FID 信号
  t = linspace(0, 5, 4000);
  T2 = 1.5;
  env = exp(-t/T2);
  f_single = 3;
  fid1 = env .* cos(2*pi*f_single*t);

  f3 = [3 7 21]; a3 = [1 1.8 0.6];
  fid3 = zeros(size(t));
  for i = 1:numel(f3)
    fid3 = fid3 + a3(i)*env.*cos(2*pi*f3(i)*t);
  end

  fEt = [29 36 43, 97.5 104.5 111.5 118.5, 150];
  aEt = [1 2 1, 1 3 3 1, 1];
  fidE = zeros(size(t));
  for i = 1:numel(fEt)
    fidE = fidE + aEt(i)*env.*cos(2*pi*fEt(i)*t);
  end

  N = numel(t); dt = t(2)-t(1); fs = 1/dt;
  freq = (0:N-1)*(fs/N); halfN = floor(N/2)+1;
  mag1 = abs(fft(fid1)); mag1 = mag1(1:halfN);
  mag3 = abs(fft(fid3)); mag3 = mag3(1:halfN);
  magE = abs(fft(fidE)); magE = magE(1:halfN);
  fr = freq(1:halfN);

  g = @(idx) oct_tile(ctx, 3, 2, idx, 0.10, 0.16, 0.095);

  % 1. 单一频率 FID
  ax1 = oct_axes(ctx.fig, g(1));
  plot(ax1, t, fid1, 'b-', 'linewidth', 1.2); hold(ax1, 'on');
  plot(ax1, t, env, 'r--', 'linewidth', 1);
  plot(ax1, t, -env, 'r--', 'linewidth', 1); hold(ax1, 'off');
  [pk, lc] = oct_findpeaks(fid1, t, 0.2*max(fid1));
  if numel(lc) >= 2
    text(ax1, mean(lc(1:2)), 1.05, sprintf('T = %.3f s', mean(diff(lc(1:2)))), ...
         'horizontalalignment', 'center');
  end
  title(ax1, sprintf('单一频率 FID (f=%d Hz, T2*=%.1f s)', f_single, T2));
  xlabel(ax1, '时间 (s)'); ylabel(ax1, '幅度');
  legend(ax1, {'FID', '包络线'}, 'location', 'northeast');
  grid(ax1, 'on'); xlim(ax1, [0 5]); ylim(ax1, [-1.3 1.3]);
  text(ax1, 0.5, -1.1, sprintf('E = ∫f²dt = %.3f', trapz(t, fid1.^2)));

  % 2. 单一频率频谱
  ax2 = oct_axes(ctx.fig, g(2));
  plot(ax2, fr, mag1, 'b-', 'linewidth', 1.5);
  set(ax2, 'xdir', 'reverse');
  title(ax2, '单一频率频谱'); xlabel(ax2, '频率 (Hz)'); ylabel(ax2, '幅度');
  grid(ax2, 'on'); xlim(ax2, [0 10]);
  text(ax2, 5, max(mag1)*0.6, sprintf('FWHM = 1/(πT2*) ≈ %.3f Hz', 1/(pi*T2)));

  % 3. 三频率 FID
  ax3 = oct_axes(ctx.fig, g(3));
  plot(ax3, t, fid3, 'm-', 'linewidth', 1.2);
  title(ax3, '三个简单频率叠加 (3,7,21 Hz)');
  xlabel(ax3, '时间 (s)'); ylabel(ax3, '幅度');
  grid(ax3, 'on'); xlim(ax3, [0 5]);

  % 4. 三频率频谱
  ax4 = oct_axes(ctx.fig, g(4));
  plot(ax4, fr, mag3, 'b-', 'linewidth', 1.5);
  set(ax4, 'xdir', 'reverse');
  title(ax4, '三个频率的频谱'); xlabel(ax4, '频率 (Hz)'); ylabel(ax4, '幅度');
  grid(ax4, 'on'); xlim(ax4, [0 25]);

  % 5. 乙醇 FID
  ax5 = oct_axes(ctx.fig, g(5));
  plot(ax5, t, fidE, 'color', [0.8 0.2 0.2], 'linewidth', 0.7);
  title(ax5, '乙醇 FID（8 个频率）'); xlabel(ax5, '时间 (s)'); ylabel(ax5, '幅度');
  grid(ax5, 'on'); xlim(ax5, [0 5]);

  % 6. 乙醇谱
  ax6 = oct_axes(ctx.fig, g(6));
  plot(ax6, fr, magE, 'b-', 'linewidth', 1.4);
  set(ax6, 'xdir', 'reverse');
  title(ax6, '乙醇 FID 的傅里叶变换（NMR 谱）'); xlabel(ax6, '频率 (Hz)'); ylabel(ax6, '幅度');
  grid(ax6, 'on'); xlim(ax6, [0 200]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤10：NMR 自由感应衰减（FID）信号（30 MHz）', 14);

  yb = d(2) + 0.02*d(4);
  uicontrol('Parent', ctx.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [d(1)+0.2*d(3), yb, 0.6*d(3), 0.055*d(4)], ...
      'String', '启动 FID 3D 动画演示', 'FontSize', 11, 'Tag', 'octstep', ...
      'BackgroundColor', [0.8 0.9 1], ...
      'Callback', @(~,~) fid_anim_octave());
end
