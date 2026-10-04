function oct_step_03(ctx)
%OCT_STEP_03 步骤3：不同数量谐波对矩形波的逼近效果
  t = linspace(-pi/2, 7*pi/2, 2000);
  sq = sign(sin(t));
  harms = [1 3 5 7 15 50];
  for i = 1:6
    ax = oct_axes(ctx.fig, oct_tile(ctx, 2, 3, i, 0.12, 0.09, 0.07));
    N = harms(i);
    ap = zeros(size(t));
    for k = 1:2:N
      ap = ap + sin(k*t)/k;
    end
    ap = (4/pi)*ap;
    plot(ax, t, ap, 'b-', 'linewidth', 1.8); hold(ax, 'on');
    plot(ax, t, sq, 'r--', 'linewidth', 1.0); hold(ax, 'off');
    title(ax, sprintf('%d 个谐波叠加', N));
    xlabel(ax, '时间'); ylabel(ax, '振幅');
    legend(ax, {'近似波形', '理想矩形波'}, 'location', 'southeast');
    grid(ax, 'on');
    xlim(ax, [-pi/2 3*pi/2]); ylim(ax, [-2.0 1.6]);
  end
  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.95, d(3), d(4)*0.05], ...
              '步骤3：不同数量谐波对矩形波的逼近效果（两个周期）', 14);
end
