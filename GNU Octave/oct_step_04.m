function oct_step_04(ctx)
%OCT_STEP_04 步骤4：信号的频率、振幅、相位（4×2）
  % Octave 版采用 2 行 × 4 列布局，为每幅子图留出更充足的垂直空间
  g = @(idx) oct_tile(ctx, 2, 4, idx, 0.10, 0.06, 0.12, 0.05, 0.07, 0.03);

  % 子图1：相位差的影响
  ax1 = oct_axes(ctx.fig, g(1));
  t = linspace(0, 2*pi, 600);
  plot(ax1, t, sin(t), 'b-', 'linewidth', 1.8); hold(ax1, 'on');
  plot(ax1, t, sin(t+pi/2), 'r--', 'linewidth', 1.8);
  plot(ax1, t, sin(t+pi), 'g:', 'linewidth', 1.8); hold(ax1, 'off');
  title(ax1, '1. 相位差的影响'); xlabel(ax1, '时间 (弧度)'); ylabel(ax1, '振幅');
  legend(ax1, {'相位0', '相位π/2', '相位π'}, 'location', 'southeast', 'fontsize', 7);
  grid(ax1, 'on'); xlim(ax1, [0 2*pi]); ylim(ax1, [-2.0 1.6]);

  % 子图2：相同频率成分、不同相位组合
  ax2 = oct_axes(ctx.fig, g(2));
  sigA = 1.0*sin(t) + 0.5*sin(3*t+pi/4);
  sigB = 1.0*sin(t+pi/2) + 0.5*sin(3*t);
  plot(ax2, t, sigA, 'b-', 'linewidth', 1.8); hold(ax2, 'on');
  plot(ax2, t, sigB, 'r--', 'linewidth', 1.8); hold(ax2, 'off');
  title(ax2, '2. 相同振幅+不同相位'); xlabel(ax2, '时间 (弧度)'); ylabel(ax2, '振幅');
  legend(ax2, {'相位组合A', '相位组合B'}, 'location', 'southwest', 'fontsize', 7);
  grid(ax2, 'on'); xlim(ax2, [0 2*pi]); ylim(ax2, [-2.0 1.6]);

  % 子图3：正弦展开振幅谱
  ax3 = oct_axes(ctx.fig, g(3));
  na = 1:9;
  bn = zeros(size(na));
  for i = 1:numel(na)
    if mod(na(i),2) == 1
      bn(i) = 4/(pi*na(i));
    end
  end
  odd = mod(na,2) == 1;
  stem(ax3, na(odd), bn(odd), 'b', 'linewidth', 1.5, 'markerfacecolor', 'b');
  hold(ax3, 'on');
  plot(ax3, na(~odd), bn(~odd), 'o', 'markersize', 6, ...
       'markerfacecolor', [0.7 0.7 0.7], 'markeredgecolor', [0.5 0.5 0.5]);
  hold(ax3, 'off');
  title(ax3, '3. 正弦展开振幅谱 b_n'); xlabel(ax3, '谐波阶数 n'); ylabel(ax3, '振幅 b_n');
  legend(ax3, {'奇次谐波', '偶次谐波 (=0)'}, 'location', 'northeast', 'fontsize', 7);
  grid(ax3, 'on'); xlim(ax3, [0.5 9.5]); ylim(ax3, [-0.1 1.5]);

  % 子图4：余弦展开振幅谱 |a_n|
  ax4 = oct_axes(ctx.fig, g(4));
  an = (4./(pi*na)).*sin(na*pi/2);
  hold(ax4, 'on');
  for i = 1:numel(na)
    if an(i) > 1e-9
      stem(ax4, na(i), abs(an(i)), 'b', 'linewidth', 1.5, 'markerfacecolor', 'b');
    elseif an(i) < -1e-9
      stem(ax4, na(i), abs(an(i)), 'r', 'linewidth', 1.5, 'markerfacecolor', 'r');
    else
      plot(ax4, na(i), 0, 'o', 'markersize', 5, ...
           'markerfacecolor', [0.7 0.7 0.7], 'markeredgecolor', [0.5 0.5 0.5]);
    end
  end
  hold(ax4, 'off');
  title(ax4, '4. 余弦展开振幅谱 |a_n|'); xlabel(ax4, '谐波阶数 n'); ylabel(ax4, '振幅');
  legend(ax4, {'正系数', '负系数', '偶次 (=0)'}, 'location', 'northeast', 'fontsize', 7);
  grid(ax4, 'on'); xlim(ax4, [0.5 9.5]); ylim(ax4, [-0.05 1.5]);

  % 子图5：正弦展开相位谱（全为 0）
  ax5 = oct_axes(ctx.fig, g(5));
  stem(ax5, na(odd), zeros(size(na(odd))), 'r', 'linewidth', 1.5, ...
       'markerfacecolor', 'r');
  title(ax5, '5. 正弦展开相位谱'); xlabel(ax5, '谐波阶数 n'); ylabel(ax5, '相位 (弧度)');
  grid(ax5, 'on'); xlim(ax5, [0.5 9.5]); ylim(ax5, [-0.5 pi+0.5]);
  yticks(ax5, [0 pi/2 pi]); yticklabels(ax5, {'0','π/2','π'});
  text(ax5, 5, pi*0.8, '所有 φ_n = 0', 'horizontalalignment', 'center');

  % 子图6：余弦展开相位谱（0 或 π）
  ax6 = oct_axes(ctx.fig, g(6));
  nz = abs(an) > 1e-10;
  ph = zeros(size(na(nz)));
  ph(an(nz) < 0) = pi;
  stem(ax6, na(nz), ph, 'm', 'linewidth', 1.5, 'markerfacecolor', 'm');
  title(ax6, '6. 余弦展开相位谱'); xlabel(ax6, '谐波阶数 n'); ylabel(ax6, '相位 (弧度)');
  grid(ax6, 'on'); xlim(ax6, [0.5 9.5]); ylim(ax6, [-0.5 pi+0.5]);
  yticks(ax6, [0 pi/2 pi]); yticklabels(ax6, {'0','π/2','π'});

  % 子图7：正弦展开时域合成
  ax7 = oct_axes(ctx.fig, g(7));
  ts = linspace(-pi/2, 7*pi/2, 1000);
  synth = zeros(size(ts));
  for k = 1:2:9
    synth = synth + (4/(pi*k))*sin(k*ts);
  end
  plot(ax7, ts, synth, 'b-', 'linewidth', 1.6); hold(ax7, 'on');
  plot(ax7, ts, sign(sin(ts)), 'r--', 'linewidth', 1.0); hold(ax7, 'off');
  title(ax7, '7. 正弦展开合成'); xlabel(ax7, '时间 (弧度)'); ylabel(ax7, '振幅');
  legend(ax7, {'正弦展开合成', '理想方波'}, 'location', 'south', 'fontsize', 7);
  grid(ax7, 'on'); xlim(ax7, [-pi/2 3*pi/2]); ylim(ax7, [-2.0 1.6]);

  % 子图8：余弦展开时域合成
  ax8 = oct_axes(ctx.fig, g(8));
  te = linspace(-pi, pi, 1000);
  syn2 = zeros(size(te));
  for k = 1:2:9
    syn2 = syn2 + ((4/(pi*k))*sin(k*pi/2))*cos(k*te);
  end
  plot(ax8, te, syn2, 'b-', 'linewidth', 1.6); hold(ax8, 'on');
  plot(ax8, te, sign(cos(te)), 'r--', 'linewidth', 1.0); hold(ax8, 'off');
  title(ax8, '8. 余弦展开合成'); xlabel(ax8, '时间 (弧度)'); ylabel(ax8, '振幅');
  legend(ax8, {'余弦展开合成', '偶对称方波'}, 'location', 'south', 'fontsize', 7);
  grid(ax8, 'on'); xlim(ax8, [-pi pi]); ylim(ax8, [-2.0 1.6]);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤4：相位谱的概念 - 完整频谱 = 振幅谱 + 相位谱', 14);
end
