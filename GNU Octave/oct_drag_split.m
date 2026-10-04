function oct_drag_split(fig)
%OCT_DRAG_SPLIT 拖动分隔条：按鼠标位置更新控制面板宽度比例
  if ~ishandle(fig)
    return;
  end
  d = getappdata(fig, 'splitdrag');
  if isempty(d) || ~d
    return;
  end
  cp = get(fig, 'currentpoint');
  p = get(fig, 'position');
  if p(3) <= 0
    return;
  end
  cf = min(max(cp(1)/p(3), 0.16), 0.55);
  S = getappdata(fig, 'ftstate');
  S.controlFrac = cf;
  setappdata(fig, 'ftstate', S);
  oct_apply_layout(fig);
  oct_show_step(fig, S.currentStep);
end
