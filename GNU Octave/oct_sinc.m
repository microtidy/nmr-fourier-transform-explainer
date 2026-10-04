function y = oct_sinc(x)
%OCT_SINC 归一化 sinc 函数 sin(pi x)/(pi x)（Signal 包 sinc 的替代）
  x = x(:)';
  y = ones(size(x));
  i = (x ~= 0);
  y(i) = sin(pi*x(i)) ./ (pi*x(i));
  y = reshape(y, size(x));
end
