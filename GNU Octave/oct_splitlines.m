function lines = oct_splitlines(raw)
%OCT_SPLITLINES 按 \r\n、\n、\r 拆分文本为 cell 数组（兼容 Octave / MATLAB）
  raw = strrep(raw, sprintf('\r\n'), sprintf('\n'));
  raw = strrep(raw, sprintf('\r'), sprintf('\n'));
  lines = strsplit(raw, sprintf('\n'));
  if numel(lines) > 0 && isempty(lines{end})
    lines(end) = [];
  end
end
