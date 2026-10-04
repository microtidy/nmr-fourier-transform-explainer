function oct_apply_layout(fig)
%OCT_APPLY_LAYOUT 按当前 controlFrac 摆放各面板与分隔条
  if ~ishandle(fig)
    return;
  end
  S = getappdata(fig, 'ftstate');
  ctx = oct_layout(fig, S.controlFrac);
  set(S.handles.ctrlPanel, 'position', ctx.ctrl);
  set(S.handles.splitter,  'position', ctx.split);
  set(S.handles.sumPanel,  'position', ctx.summary);
  if isfield(S.handles, 'dispLabel') && ishandle(S.handles.dispLabel)
    d = ctx.disp;
    set(S.handles.dispLabel, 'position', ...
        [d(1)+0.005, d(2)+d(4)-0.035, 0.22, 0.032]);
  end
end
