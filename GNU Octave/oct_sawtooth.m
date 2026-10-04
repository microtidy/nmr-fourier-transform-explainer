function y = oct_sawtooth(t, width)
%OCT_SAWTOOTH 锯齿波（Signal 包 sawtooth 的替代实现）
  if nargin < 2 || isempty(width)
    width = 1;
  end
  per = 2*pi;
  ph = mod(t, per) / per;          % 0..1
  y = zeros(size(t));
  if width <= 0
    y = 2*ph - 1;
  else
    i1 = ph < width;
    y(i1) = ph(i1)/width;
    y(~i1) = 1 - (ph(~i1) - width)/(1 - width);
    y = 2*y - 1;
  end
end
