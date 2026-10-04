function [pks, locs] = oct_findpeaks(y, x, minHeight)
%OCT_FINDPEAKS 简易峰值检测（Signal 包 findpeaks 的替代实现）
%   [PKS, LOCS] = OCT_FINDPEAKS(Y) 返回局部极大值及其下标；
%   给出 X 时返回对应的 X 位置；可用 MINHEIGHT 过滤。
  y = y(:).';
  if nargin >= 2 && ~isempty(x)
    x = x(:).';
  else
    x = 1:numel(y);
  end
  if nargin < 3 || isempty(minHeight)
    minHeight = -inf;
  end
  locs = [];
  pks  = [];
  for i = 2:numel(y)-1
    if y(i) > y(i-1) && y(i) >= y(i+1) && y(i) >= minHeight
      locs(end+1) = i;   %#ok<AGROW>
      pks(end+1)  = y(i); %#ok<AGROW>
    end
  end
  locs = x(locs);
end
