function oct_setup_fonts()
%OCT_SETUP_FONTS 为绘图与控件设置支持中文的默认字体
  if ispc
    name = 'Microsoft YaHei';
  elseif ismac
    name = 'PingFang SC';
  else
    name = 'Noto Sans CJK SC';
  end
  try
    set(0, 'defaultaxesfontname', name);
    set(0, 'defaulttextfontname', name);
    set(0, 'defaultuicontrolfontname', name);
    set(0, 'defaultaxesfontsize', 9);
    set(0, 'defaulttextfontsize', 9);
  catch
    % 忽略：字体不可用时使用系统默认
  end
end
