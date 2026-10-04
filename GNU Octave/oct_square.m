function y = oct_square(t, duty)
%OCT_SQUARE 方波（Signal 包 square 的替代实现）
  if nargin < 2 || isempty(duty)
    duty = 50;
  end
  per = 2*pi;
  ph = mod(t, per) / per;          % 0..1
  y = 2*(ph < duty/100) - 1;
end
