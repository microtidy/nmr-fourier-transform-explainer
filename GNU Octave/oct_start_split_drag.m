function oct_start_split_drag(fig)
%OCT_START_SPLIT_DRAG 开始拖动分隔条
  setappdata(fig, 'splitdrag', true);
  try
    set(fig, 'pointer', 'left');
  catch
  end
  set(fig, 'windowbuttonmotionfcn', @(~,~) oct_drag_split(fig));
  set(fig, 'windowbuttonupfcn',     @(~,~) oct_stop_split_drag(fig));
end
