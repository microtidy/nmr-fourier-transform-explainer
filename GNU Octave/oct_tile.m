function p = oct_tile(ctx, nR, nC, idx, topPad, botPad, vGap, hGap, leftPad, rightPad)
%OCT_TILE 计算第 IDX 个子图在 figure 中的绝对归一化位置
%   POS = OCT_TILE(CTX, NR, NC, IDX) 默认留出较宽的标签间距。
  if nargin < 5  || isempty(topPad),   topPad   = 0.10;  end
  if nargin < 6  || isempty(botPad),   botPad   = 0.07;  end
  if nargin < 7  || isempty(vGap),     vGap     = 0.06;  end
  if nargin < 8  || isempty(hGap),     hGap     = 0.07;  end
  if nargin < 9  || isempty(leftPad),  leftPad  = 0.080; end
  if nargin < 10 || isempty(rightPad), rightPad = 0.035; end

  D = ctx.disp;
  tileW = (1 - leftPad - rightPad - (nC-1)*hGap) / nC;
  tileH = (1 - topPad - botPad - (nR-1)*vGap) / nR;
  r = floor((idx-1)/nC) + 1;
  c = mod(idx-1, nC) + 1;
  x = D(1) + (leftPad + (c-1)*(tileW + hGap)) * D(3);
  y = D(2) + (1 - topPad - r*tileH - (r-1)*vGap) * D(4);
  p = [x, y, tileW*D(3), tileH*D(4)];
end
