function oct_demo_reset(fig)
%OCT_DEMO_RESET 采样演示参数复位
  S = getappdata(fig, 'demostate');
  set(S.slF0, 'value', 2);
  set(S.slFs, 'value', 8);
  oct_demo_update(fig);
end
