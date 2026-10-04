function oct_show_step(fig, k)
%OCT_SHOW_STEP 切换到第 K 步：清除旧图、绘制新图、更新文本
  if ~ishandle(fig)
    return;
  end
  S = getappdata(fig, 'ftstate');
  n = numel(S.stepTitles);
  if k < 1 || k > n
    return;
  end
  S.currentStep = k;
  setappdata(fig, 'ftstate', S);

  ctx = oct_layout(fig, S.controlFrac);
  oct_clear_axes(fig);

  switch k
    case 1,  oct_step_01(ctx);
    case 2,  oct_step_02(ctx);
    case 3,  oct_step_03(ctx);
    case 4,  oct_step_04(ctx);
    case 5,  oct_step_05(ctx);
    case 6,  oct_step_06(ctx);
    case 7,  oct_step_07(ctx);
    case 8,  oct_step_08(ctx);
    case 9,  oct_step_09(ctx);
    case 10, oct_step_10(ctx);
    case 11, oct_step_11(ctx, S.operationInstructions{k});
  end

  set(S.handles.explanationText, 'string', S.explanationContents{k});
  set(S.handles.summaryText, 'string', S.summaryContents{k});
  drawnow();
end
