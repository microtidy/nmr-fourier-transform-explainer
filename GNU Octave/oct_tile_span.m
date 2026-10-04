function p = oct_tile_span(ctx, nR, nC, idxList, varargin)
%OCT_TILE_SPAN 计算跨越多格（如 [4 6]）的子图位置（各格位置的并集）
  p1 = oct_tile(ctx, nR, nC, idxList(1), varargin{:});
  x1 = p1(1); y1 = p1(2); x2 = p1(1)+p1(3); y2 = p1(2)+p1(4);
  for k = 2:numel(idxList)
    pk = oct_tile(ctx, nR, nC, idxList(k), varargin{:});
    x1 = min(x1, pk(1)); y1 = min(y1, pk(2));
    x2 = max(x2, pk(1)+pk(3)); y2 = max(y2, pk(2)+pk(4));
  end
  p = [x1, y1, x2-x1, y2-y1];
end
