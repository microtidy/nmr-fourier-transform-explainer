function ax = oct_axes(fig, pos)
%OCT_AXES 在 figure 上按归一化位置创建坐标轴（带统一 Tag 便于清理）
  ax = axes('Parent', fig, 'Units', 'normalized', 'Position', pos, ...
            'Tag', 'octax');
end
