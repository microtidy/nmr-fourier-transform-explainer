function oct_show_step_instructions(fig)
%OCT_SHOW_STEP_INSTRUCTIONS 弹出当前步骤的详细讲解
  S = getappdata(fig, 'ftstate');
  k = S.currentStep;
  if k >= 1 && k <= numel(S.operationInstructions)
    oct_show_text_window(sprintf('步骤%d 详细讲解', k), S.operationInstructions{k});
  end
end
