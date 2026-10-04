function oct_anim_toggle(fig, kind)
%OCT_ANIM_TOGGLE 暂停/继续动画
  key = ['anim_' kind];
  st = getappdata(fig, key);
  if st.running
    st.running = false;
    setappdata(fig, key, st);
  else
    oct_anim_run(fig, kind);
  end
end
