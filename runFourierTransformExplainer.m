function runFourierTransformExplainer()
% RUNFOURIERTRANSFORMEXPLAINER 启动傅里叶变换讲解器应用程序
%   清理工作区并启动主应用GUI，提供错误处理和用户引导。

% 清理环境（使用更安全的方式）
close all force;
clc;

fprintf('正在启动傅里叶变换讲解器...\n');

% 启动应用程序
try
    app = FourierTransformExplainer(); %#ok<NASGU>  % app对象由GUI回调持有，此处无需显式使用
    fprintf('应用程序启动成功！\n');
    fprintf('使用方法：\n');
    fprintf('  1. 点击左侧按钮选择讲解步骤\n');
    fprintf('  2. 使用"上一步"和"下一步"按钮导航\n');
    fprintf('  3. 右侧显示对应的原理图像\n');
catch ME
    fprintf(2, '启动应用程序时出错：\n');
    fprintf(2, '  错误信息: %s\n', ME.message);
    fprintf(2, '  错误ID: %s\n', ME.identifier);
    fprintf('请确保所有函数文件在MATLAB路径中。\n');
    rethrow(ME);
end
end
