function oct_step_05(ctx)
%OCT_STEP_05 步骤5：欧拉公式与旋转向量
  % 左图：复平面上的单位圆与旋转向量
  ax1 = oct_axes(ctx.fig, oct_tile(ctx, 1, 2, 1, 0.10, 0.10, 0.05, 0.10, 0.10, 0.03));
  th = linspace(0, 2*pi, 400);
  plot(ax1, cos(th), sin(th), 'k-', 'linewidth', 1.2); hold(ax1, 'on');
  plot(ax1, [-1.3 1.3], [0 0], 'k:');
  plot(ax1, [0 0], [-1.3 1.3], 'k:');
  angs = 0:pi/4:2*pi-pi/4;
  cols = oct_parula(numel(angs));
  for i = 1:numel(angs)
    a = angs(i);
    plot(ax1, [0 cos(a)], [0 sin(a)], '-', 'color', cols(i,:), 'linewidth', 2);
    plot(ax1, cos(a), sin(a), 'o', 'markerfacecolor', cols(i,:), 'markersize', 6);
  end
  a1 = pi/4;
  plot(ax1, [cos(a1) cos(a1)], [0 sin(a1)], 'color', [0.9 0.5 0], 'linewidth', 2);
  plot(ax1, [0 cos(a1)], [sin(a1) sin(a1)], 'g-', 'linewidth', 2);
  text(ax1, 0.55, -0.18, 'cosθ', 'color', [0.9 0.5 0]);
  text(ax1, -0.05, 0.8, 'sinθ', 'color', [0 0.6 0]);
  text(ax1, 0.72, 0.78, 'e^{iθ}', 'fontsize', 12);
  hold(ax1, 'off'); grid(ax1, 'on'); axis(ax1, [-1.4 1.4 -1.4 1.4]);
  title(ax1, '1. 复平面：单位圆与旋转向量');
  xlabel(ax1, '实部 Re (cosθ)'); ylabel(ax1, '虚部 Im (sinθ)');

  % 右图：3D 螺旋线 e^{iθ} 及其投影
  ax2 = oct_axes(ctx.fig, oct_tile(ctx, 1, 2, 2, 0.10, 0.10, 0.05, 0.10, 0.03, 0.03));
  u = linspace(0, 4*pi, 600);
  x = cos(u); y = sin(u); z = u;
  plot3(ax2, x, y, z, 'b-', 'linewidth', 2); hold(ax2, 'on');
  plot3(ax2, x, y, zeros(size(z)), 'g-', 'linewidth', 1);        % 底圆
  plot3(ax2, x, -1.4*ones(size(z)), z, 'color', [0.9 0.5 0], 'linewidth', 1);
  plot3(ax2, 1.4*ones(size(z)), y, z, 'color', [0.8 0 0.8], 'linewidth', 1);
  hold(ax2, 'off'); grid(ax2, 'on');
  xlabel(ax2, '实部 cosθ'); ylabel(ax2, '虚部 sinθ'); zlabel(ax2, 'θ');
  title(ax2, '2. 3D 螺旋线：e^{iθ} = cosθ + i·sinθ');
  legend(ax2, {'e^{iθ} 螺旋线', '单位圆', 'cosθ 投影', 'sinθ 投影'}, ...
         'location', 'southwest');
  view(ax2, 35, 22);

  d = ctx.disp;
  oct_sgtitle(ctx.fig, [d(1), d(2)+d(4)*0.955, d(3), d(4)*0.045], ...
              '步骤5：欧拉公式与复平面', 14);
end
