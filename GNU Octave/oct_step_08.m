function oct_step_08(ctx)
%OCT_STEP_08 步骤8：采样定理——完全采样与混叠
  f0 = 3; fsGood = 8; fsBad = 4; Twin = 1;
  t = linspace(0, Twin, 3000);
  x = sin(2*pi*f0*t);
  g = @(idx) oct_tile(ctx, 3, 2, idx, 0.105, 0.15, 0.09);

  % 1. 满足采样定理
  ax1 = oct_axes(ctx.fig, g(1));
  ts = 0:1/fsGood:Twin;
  plot(ax1, t, x, 'b-', 'linewidth', 1.5); hold(ax1, 'on');
  stem(ax1, ts, sin(2*pi*f0*ts), 'r', 'markerfacecolor', 'r');
  plot(ax1, t, x, 'g--', 'linewidth', 1.2); hold(ax1, 'off');
  title(ax1, sprintf('1. 满足采样定理：f_s=%.0f Hz > 2f_0=%.0f Hz', fsGood, 2*f0));
  xlabel(ax1, '时间 (s)'); ylabel(ax1, '幅度');
  legend(ax1, {'真实信号', '采样点', '恢复信号'}, 'location', 'northeast');
  grid(ax1, 'on'); xlim(ax1, [0 Twin]); ylim(ax1, [-1.6 2.5]);
  text(ax1, Twin/2, -1.45, '采样足够密 → 可无失真复原', 'horizontalalignment', 'center');

  % 2. 频谱周期延拓（不重叠）
  ax2 = oct_axes(ctx.fig, g(2));
  fmax2 = 2*fsGood;
  rep = sort([f0, fsGood-f0, fsGood+f0, 2*fsGood-f0]);
  hold(ax2, 'on');
  % 无重叠区（用矩形示意）
  rectangle('Parent', ax2, 'Position', [0 0 fsGood/2 1.2], ...
            'FaceColor', [0.8 1 0.8], 'EdgeColor', 'none');
  for k = 1:numel(rep)
    stem(ax2, rep(k), 1, 'b', 'linewidth', 1.4, 'markerfacecolor', 'b');
  end
  plot(ax2, [fsGood/2 fsGood/2], [0 1.2], 'k--', 'linewidth', 1);
  hold(ax2, 'off'); grid(ax2, 'on');
  title(ax2, '2. 采样频谱：以 f_s 为周期延拓'); xlabel(ax2, '频率 (Hz)'); ylabel(ax2, '相对幅度');
  xlim(ax2, [0 fmax2]); ylim(ax2, [0 1.45]);
  text(ax2, fsGood/2, 1.3, 'f_s/2', 'horizontalalignment', 'center');

  % 3. 欠采样：采样点伪装成低频
  ax3 = oct_axes(ctx.fig, g(3));
  tb = 0:1/fsBad:Twin;
  fEff = f0 - fsBad*round(f0/fsBad);
  plot(ax3, t, x, 'b-', 'linewidth', 1.5); hold(ax3, 'on');
  stem(ax3, tb, sin(2*pi*f0*tb), 'r', 'markerfacecolor', 'r');
  plot(ax3, t, sin(2*pi*fEff*t), 'm--', 'linewidth', 1.6); hold(ax3, 'off');
  title(ax3, sprintf('3. 欠采样：f_s=%.0f Hz < 2f_0=%.0f Hz', fsBad, 2*f0));
  xlabel(ax3, '时间 (s)'); ylabel(ax3, '幅度');
  legend(ax3, {'真实信号 (3 Hz)', '采样点', '恢复信号 (1 Hz 假象)'}, ...
         'location', 'northeast');
  grid(ax3, 'on'); xlim(ax3, [0 Twin]); ylim(ax3, [-1.6 2.5]);
  text(ax3, Twin/2, -1.45, '采样点落在 1 Hz 正弦波上 → 无法分辨', ...
       'horizontalalignment', 'center');

  % 4. 频谱重叠（折叠）
  ax4 = oct_axes(ctx.fig, g(4));
  hold(ax4, 'on');
  rectangle('Parent', ax4, 'Position', [0 0 fsBad/2 1.2], ...
            'FaceColor', [1 0.85 0.85], 'EdgeColor', 'none');
  stem(ax4, f0, 1, 'b', 'linewidth', 1.5, 'markerfacecolor', 'b');
  stem(ax4, abs(fEff), 1, 'r', 'linewidth', 1.5, 'markerfacecolor', 'r');
  plot(ax4, [fsBad/2 fsBad/2], [0 1.2], 'k--', 'linewidth', 1);
  hold(ax4, 'off'); grid(ax4, 'on');
  title(ax4, '4. 频谱重叠：3 Hz 折叠为 1 Hz'); xlabel(ax4, '频率 (Hz)'); ylabel(ax4, '相对幅度');
  xlim(ax4, [0 2*fsBad]); ylim(ax4, [0 1.45]);
  text(ax4, f0, 1.1, '真实 3 Hz', 'color', 'b', 'horizontalalignment', 'center');
  text(ax4, abs(fEff), 0.85, '混叠 1 Hz', 'color', 'r', 'horizontalalignment', 'center');

  % 5. 混叠频率关系（锯齿图）
  ax5 = oct_axes(ctx.fig, g(5));
  fr = linspace(0, 3*fsBad, 2000);
  fAl = abs(fr - fsBad*round(fr/fsBad));
  plot(ax5, fr, fAl, 'b-', 'linewidth', 1.7); hold(ax5, 'on');
  plot(ax5, [0 3*fsBad], [fsBad/2 fsBad/2], 'k--', 'linewidth', 1);
  plot(ax5, f0, abs(fEff), 'ro', 'markerfacecolor', 'r', 'markersize', 8);
  hold(ax5, 'off'); grid(ax5, 'on');
  title(ax5, '5. 混叠频率关系（f_s=4 Hz）');
  xlabel(ax5, '真实频率 f (Hz)'); ylabel(ax5, '观察到的频率 (Hz)');
  xlim(ax5, [0 3*fsBad]); ylim(ax5, [0 fsBad/2+0.3]);

  % 6. NMR 应用：谱宽与折叠
  ax6 = oct_axes(ctx.fig, g(6));
  SW = 20;
  off = linspace(-SW/2, SW/2, 1500);
  genuine = exp(-((off-4)/0.6).^2);
  folded  = exp(-((off+7)/0.6).^2);
  plot(ax6, off, genuine, 'b-', 'linewidth', 1.7); hold(ax6, 'on');
  plot(ax6, off, folded, 'r--', 'linewidth', 1.7); hold(ax6, 'off');
  title(ax6, '6. NMR：谱宽 SW=1/dwell，观测 ±SW/2');
  xlabel(ax6, '相对载频的偏移频率 (kHz)'); ylabel(ax6, '幅度');
  xlim(ax6, [-SW/2 SW/2]); ylim(ax6, [-0.5 1.25]);
  text(ax6, 4, 1.12, '真实峰', 'color', 'b', 'horizontalalignment', 'center');
  text(ax6, -7, 1.12, '折叠峰', 'color', 'r', 'horizontalalignment', 'center');
  text(ax6, 0, -0.4, '真实位置 +13 kHz（> +SW/2）→ 折叠到 -7 kHz', ...
       'color', 'r', 'horizontalalignment', 'center');

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤8：采样定理——完全采样与避免混叠', 14);

  yb = d(2) + 0.02*d(4);
  uicontrol('Parent', ctx.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
      'Position', [d(1)+0.2*d(3), yb, 0.6*d(3), 0.055*d(4)], ...
      'String', '启动采样混叠交互演示', 'FontSize', 11, 'Tag', 'octstep', ...
      'BackgroundColor', [1 0.9 0.8], ...
      'Callback', @(~,~) sampling_aliasing_demo_octave());
end
