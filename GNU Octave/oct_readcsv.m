function data = oct_readcsv(filePath)
%OCT_READCSV 读取讲解文本 CSV，返回 N×5 cell（第 1 行为表头）
%   与 MATLAB 版一致的引号边界解析，兼容部分字段未加引号的情况。
  raw = fileread(filePath);
  if ~isempty(raw) && double(raw(1)) == 65279      % 去除 UTF-8 BOM
    raw = raw(2:end);
  end
  lines = oct_splitlines(raw);
  lines = lines(~cellfun(@(s) isempty(strtrim(s)), lines));

  data = cell(numel(lines), 5);
  data(:) = {''};
  n = 0;
  for li = 1:numel(lines)
    line = strtrim(lines{li});
    if isempty(line)
      continue;
    end
    n = n + 1;
    fields = oct_splitquoted(line);
    for fi = 1:min(numel(fields), 5)
      data{n, fi} = fields{fi};
    end
  end
  data = data(1:n, :);
end

function fields = oct_splitquoted(str)
  fields = {};
  current = '';
  inQuotes = false;
  for j = 1:numel(str)
    c = str(j);
    if c == '"'
      inQuotes = ~inQuotes;
      current(end+1) = c;             %#ok<AGROW>
    elseif c == ',' && ~inQuotes
      fields{end+1} = oct_trimunquote(current); %#ok<AGROW>
      current = '';
    else
      current(end+1) = c;             %#ok<AGROW>
    end
  end
  fields{end+1} = oct_trimunquote(current);
end

function s = oct_trimunquote(s)
  s = strtrim(s);
  if numel(s) >= 2 && s(1) == '"' && s(end) == '"'
    s = s(2:end-1);
  end
  s = strrep(s, '""', '"');
end
