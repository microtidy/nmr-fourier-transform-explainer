function oct_demo_update(fig)
%OCT_DEMO_UPDATE 按当前滑块值刷新采样演示
  S = getappdata(fig, 'demostate');
  f0 = get(S.slF0, 'value');
  fs = get(S.slFs, 'value');
  set(S.lblF0, 'string', sprintf('%.2f Hz', f0));
  set(S.lblFs, 'string', sprintf('%.2f Hz', fs));

  Twin = 1;
  t = linspace(0, Twin, 3000);
  x = sin(2*pi*f0*t);
  ts = 0:1/fs:Twin;
  xs = sin(2*pi*f0*ts);
  fEff = f0 - fs*round(f0/fs);
  falias = abs(fEff);
  xa = sin(2*pi*fEff*t);
  aliased = fs <= 2*f0 + 1e-9;

  % 时域
  cla(S.axT);
  hold(S.axT, 'on');
  plot(S.axT, t, x, 'b-', 'linewidth', 1.6);
  stem(S.axT, ts, xs, 'r', 'markerfacecolor', 'r');
  plot(S.axT, t, xa, 'm--', 'linewidth', 1.5);
  hold(S.axT, 'off'); grid(S.axT, 'on');
  xlabel(S.axT, '时间 (s)'); ylabel(S.axT, '幅度');
  xlim(S.axT, [0 Twin]); ylim(S.axT, [-1.8 1.8]);
  title(S.axT, sprintf('时域：f_0=%.2f Hz，f_s=%.2f Hz（%d 个采样点）', ...
        f0, fs, numel(ts)));
  legend(S.axT, {'真实连续信号', '采样点', '由采样点恢复的信号'}, ...
         'location', 'south');
  if aliased
    text(S.axT, Twin/2, 1.55, '恢复信号 ≠ 真实信号 → 发生混叠', ...
         'color', [0.8 0 0], 'horizontalalignment', 'center', 'fontweight', 'bold');
  else
    text(S.axT, Twin/2, 1.55, '恢复信号与真实信号重合 → 无混叠', ...
         'color', [0 0.5 0], 'horizontalalignment', 'center', 'fontweight', 'bold');
  end

  % 频域
  cla(S.axF);
  fmax = max([fs, 2*f0, 1])*1.15;
  hold(S.axF, 'on');
  rectangle('Parent', S.axF, 'Position', [0 0 fs/2 1.25], ...
            'FaceColor', [0.85 1 0.85], 'EdgeColor', 'none');
  stem(S.axF, f0, 1, 'b', 'linewidth', 1.5, 'markerfacecolor', 'b');
  stem(S.axF, falias, 0.7, 'r', 'linewidth', 1.5, 'markerfacecolor', 'r');
  plot(S.axF, [fs/2 fs/2], [0 1.3], 'k--', 'linewidth', 1.1);
  hold(S.axF, 'off'); grid(S.axF, 'on');
  xlim(S.axF, [0 fmax]); ylim(S.axF, [0 1.4]);
  xlabel(S.axF, '频率 (Hz)'); ylabel(S.axF, '相对幅度');
  title(S.axF, sprintf('频域：奈奎斯特频率 f_s/2 = %.2f Hz', fs/2));

  if aliased
    status = '欠采样 → 发生混叠';
  else
    status = '满足采样定理 → 无混叠';
  end
  info = sprintf(['信号频率 f0 = %.2f Hz\n' ...
                  '采样频率 fs = %.2f Hz\n' ...
                  '奈奎斯特频率 fs/2 = %.2f Hz\n' ...
                  '最小采样率 2f0 = %.2f Hz\n' ...
                  '表观(混叠)频率 = %.2f Hz\n' ...
                  '状态：%s'], f0, fs, fs/2, 2*f0, falias, status);
  set(S.txt, 'string', info);
  drawnow();
end
