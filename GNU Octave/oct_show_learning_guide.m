function oct_show_learning_guide(fig)
%OCT_SHOW_LEARNING_GUIDE 弹出学习指南
  S = getappdata(fig, 'ftstate');
  oct_show_text_window('傅里叶变换学习指南', S.learningGuideContent);
end
