function oct_anim_run(fig, kind)
%OCT_ANIM_RUN 播放指定动画（循环逐帧刷新，可被“暂停”中断）
  key = ['anim_' kind];
  st = getappdata(fig, key);
  st.running = true;
  setappdata(fig, key, st);
  while true
    st = getappdata(fig, key);
    if isempty(st) || ~st.running || st.frame >= st.maxFrame
      break;
    end
    st.frame = st.frame + 1;
    setappdata(fig, key, st);
    oct_anim_draw(fig, kind);
    drawnow();
    pause(0.03);
  end
  st = getappdata(fig, key);
  if ~isempty(st)
    st.running = false;
    setappdata(fig, key, st);
    oct_anim_draw(fig, kind);
  end
end
