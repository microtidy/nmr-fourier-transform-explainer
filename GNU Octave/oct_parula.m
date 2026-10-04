function cmap = oct_parula(n)
%OCT_PARULA 返回 parula 风格配色；若系统自带 parula 则直接使用
  if nargin < 1 || isempty(n)
    n = 64;
  end
  if exist('parula', 'file') == 2
    cmap = parula(n);
    return;
  end
  % 近似的 parula 简化实现（蓝→青→绿→黄）
  anchors = [0.2081 0.1663 0.5292;
             0.0770 0.5040 0.8385;
             0.0230 0.6905 0.6687;
             0.2928 0.7493 0.4393;
             0.6579 0.7790 0.2931;
             0.9763 0.9831 0.0538];
  x = linspace(0, 1, size(anchors, 1));
  xi = linspace(0, 1, n)';
  cmap = [interp1(x, anchors(:,1), xi), ...
          interp1(x, anchors(:,2), xi), ...
          interp1(x, anchors(:,3), xi)];
end
