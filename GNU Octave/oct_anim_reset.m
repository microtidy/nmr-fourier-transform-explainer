function oct_anim_reset(fig, kind)
%OCT_ANIM_RESET 重置动画到初始帧
  key = ['anim_' kind];
  st = getappdata(fig, key);
  st.frame = 0;
  st.running = false;
  setappdata(fig, key, st);
  oct_anim_draw(fig, kind);
end
