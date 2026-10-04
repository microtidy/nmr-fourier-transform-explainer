function oct_anim_draw(fig, kind)
%OCT_ANIM_DRAW 绘制指定动画的当前帧
  key = ['anim_' kind];
  st = getappdata(fig, key);
  switch kind
    case 'series', oct_anim_draw_series(st);
    case 'circle', oct_anim_draw_circle(st);
    case 'fid',    oct_anim_draw_fid(st);
  end
  drawnow();
end

function oct_anim_draw_series(st)
  p = max(st.frame, 1) / st.maxFrame;
  th = 2*pi*p;
  ns = [1 3 5 7 9];
  cols = oct_parula(numel(ns));
  cla(st.axC); hold(st.axC, 'on');
  plot(st.axC, cos(linspace(0,2*pi,200)), sin(linspace(0,2*pi,200)), 'k:');
  sx = 0; sy = 0;
  for i = 1:numel(ns)
    r = 4/(pi*ns(i));
    ex = r*cos(ns(i)*th);
    ey = r*sin(ns(i)*th);
    plot(st.axC, [sx sx+ex], [sy sy+ey], 'color', cols(i,:), 'linewidth', 2);
    sx = sx + ex;
    sy = sy + ey;
  end
  plot(st.axC, [0 sx], [0 sy], 'k-', 'linewidth', 3);
  hold(st.axC, 'off'); grid(st.axC, 'on'); axis(st.axC, [-2 2 -2 2]);
  title(st.axC, '复平面：各次谐波向量叠加');

  t = linspace(0, 2*pi, 400);
  sumv = zeros(size(t));
  for i = 1:numel(ns)
    sumv = sumv + (4/(pi*ns(i)))*sin(ns(i)*t);
  end
  cla(st.axT); hold(st.axT, 'on');
  plot(st.axT, t, sign(sin(t)), 'r--', 'linewidth', 1.3);
  plot(st.axT, t, sumv, 'b-', 'linewidth', 2);
  plot(st.axT, th, interp1(t, sumv, th), 'go', 'markerfacecolor', 'g', 'markersize', 8);
  hold(st.axT, 'off'); grid(st.axT, 'on');
  xlim(st.axT, [0 2*pi]); ylim(st.axT, [-1.6 1.6]);
  title(st.axT, '时域：前 5 个奇次谐波叠加矩形波');
  xlabel(st.axT, '时间 (弧度)'); ylabel(st.axT, '振幅');
end

function oct_anim_draw_circle(st)
  p = max(st.frame, 1) / st.maxFrame;
  th = 2*pi*p;
  cla(st.axC); hold(st.axC, 'on');
  plot(st.axC, cos(linspace(0,2*pi,200)), sin(linspace(0,2*pi,200)), 'k:');
  plot(st.axC, [0 cos(th)], [0 sin(th)], 'b-', 'linewidth', 2);
  plot(st.axC, cos(th), sin(th), 'bo', 'markerfacecolor', 'b', 'markersize', 8);
  plot(st.axC, [cos(th) cos(th)], [0 sin(th)], 'color', [0.9 0.5 0], 'linewidth', 2);
  plot(st.axC, [0 cos(th)], [sin(th) sin(th)], 'g-', 'linewidth', 2);
  hold(st.axC, 'off'); grid(st.axC, 'on'); axis(st.axC, [-1.5 1.5 -1.5 1.5]);
  title(st.axC, '旋转向量 e^{iθ} 及其投影');

  t = linspace(0, 2*pi, 400);
  cla(st.axT); hold(st.axT, 'on');
  plot(st.axT, t, sin(t), 'g-', 'linewidth', 2);
  plot(st.axT, t, cos(t), 'color', [0.9 0.5 0], 'linewidth', 2);
  plot(st.axT, th, sin(th), 'go', 'markerfacecolor', 'g', 'markersize', 8);
  hold(st.axT, 'off'); grid(st.axT, 'on');
  xlim(st.axT, [0 2*pi]); ylim(st.axT, [-1.4 1.4]);
  title(st.axT, '投影得到正弦（绿）与余弦（橙）');
  xlabel(st.axT, 'θ'); ylabel(st.axT, '投影值');
end

function oct_anim_draw_fid(st)
  p = max(st.frame, 1) / st.maxFrame;
  T2 = 1.5; f0 = 3; tmax = 5;
  t = linspace(0, tmax, 1200);
  env = exp(-t/T2);
  fid = env .* cos(2*pi*f0*t);

  cla(st.axT); hold(st.axT, 'on');
  plot(st.axT, t, env, 'r--', 'linewidth', 1);
  plot(st.axT, t, -env, 'r--', 'linewidth', 1);
  plot(st.axT, t, fid, 'b-', 'linewidth', 1.2);
  tk = p*tmax;
  plot(st.axT, tk, interp1(t, fid, tk), 'go', 'markerfacecolor', 'g', 'markersize', 8);
  plot(st.axT, [tk tk], [-1.2 1.2], 'k:', 'linewidth', 1);
  hold(st.axT, 'off'); grid(st.axT, 'on');
  xlim(st.axT, [0 tmax]); ylim(st.axT, [-1.3 1.3]);
  title(st.axT, 'FID：射频激发后的自由感应衰减信号');
  xlabel(st.axT, '时间 (s)'); ylabel(st.axT, '幅度');

  cla(st.ax3); hold(st.ax3, 'on');
  tt = linspace(0, max(tk, 0.01), 400);
  ex = exp(-tt/T2);
  plot3(st.ax3, ex.*cos(2*pi*f0*tt), ex.*sin(2*pi*f0*tt), tt, 'b-', 'linewidth', 1.6);
  plot3(st.ax3, [0 1], [0 0], [0 0], 'k-');
  hold(st.ax3, 'off'); grid(st.ax3, 'on');
  xlabel(st.ax3, 'Mx'); ylabel(st.ax3, 'My'); zlabel(st.ax3, '时间 t');
  title(st.ax3, '磁化矢量横向分量的衰减螺旋');
  view(st.ax3, 35, 20); axis(st.ax3, [-1 1 -1 1 0 tmax]);
end
