function oct_clear_axes(fig)
%OCT_CLEAR_AXES 删除本程序创建的绘图坐标轴、总标题与步骤专用控件
  hands = findobj(fig, 'type', 'axes');
  for k = 1:numel(hands)
    tg = get(hands(k), 'tag');
    if strcmp(tg, 'octax') || strcmp(tg, 'oct_sgtitle')
      delete(hands(k));
    end
  end
  ctrls = findobj(fig, 'type', 'uicontrol');
  for k = 1:numel(ctrls)
    if strcmp(get(ctrls(k), 'tag'), 'octstep')
      delete(ctrls(k));
    end
  end
  drawnow();
end
