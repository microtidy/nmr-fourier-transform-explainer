function ctx = oct_layout(fig, controlFrac, summaryH)
%OCT_LAYOUT 计算主界面各区域（归一化坐标），供坐标轴与控件定位使用
  if nargin < 2 || isempty(controlFrac)
    controlFrac = 0.24;
  end
  if nargin < 3 || isempty(summaryH)
    summaryH = 0.115;
  end
  m  = 0.008;
  sw = 0.009;
  cf = min(max(controlFrac, 0.16), 0.55);

  ctx.fig = fig;
  ctx.controlFrac = cf;
  ctx.m = m;
  ctx.ctrl    = [m, m, cf - m - sw/2, 1 - 2*m];
  ctx.split   = [cf - sw/2, m, sw, 1 - 2*m];
  dLeft  = cf + sw/2 + m;
  dWidth = 1 - dLeft - m;
  ctx.summary = [dLeft, m, dWidth, summaryH];
  dBottom = m + summaryH + m;
  ctx.disp = [dLeft, dBottom, dWidth, 1 - dBottom - m];
end
