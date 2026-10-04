function oct_msgbox(msg, title)
%OCT_MSGBOX 简单的消息框封装（Octave 下用 msgbox，失败则打印到命令行）
  if nargin < 2
    title = '提示';
  end
  try
    msgbox(msg, title);
  catch
    fprintf('%s: %s\n', title, msg);
  end
end
