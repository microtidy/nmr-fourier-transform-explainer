function oct_stop_split_drag(fig)
%OCT_STOP_SPLIT_DRAG 结束拖动
  if ~ishandle(fig)
    return;
  end
  setappdata(fig, 'splitdrag', false);
  try
    set(fig, 'pointer', 'arrow');
  catch
  end
  set(fig, 'windowbuttonmotionfcn', '');
  set(fig, 'windowbuttonupfcn', '');
end
