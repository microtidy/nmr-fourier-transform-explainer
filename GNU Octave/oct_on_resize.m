function oct_on_resize(fig)
%OCT_ON_RESIZE 窗口缩放回调：限制最小尺寸并按新尺寸重绘当前步骤
  if ~ishandle(fig)
    return;
  end
  if isappdata(fig, 'in_resize') && getappdata(fig, 'in_resize')
    return;
  end
  setappdata(fig, 'in_resize', true);
  p = get(fig, 'position');
  nw = max(p(3), 980);
  nh = max(p(4), 640);
  if nw ~= p(3) || nh ~= p(4)
    set(fig, 'position', [p(1), p(2), nw, nh]);
  end
  oct_apply_layout(fig);
  S = getappdata(fig, 'ftstate');
  oct_show_step(fig, S.currentStep);
  setappdata(fig, 'in_resize', false);
end
