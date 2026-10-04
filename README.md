# NMR 傅里叶变换原理讲解器

> 一套面向核磁共振（PFT-NMR）与信号处理教学的可视化演示软件。
> 提供 **MATLAB 版** 与 **GNU Octave 版** 两套实现，功能一致，便于没有 MATLAB 授权的院校使用。

本软件把「时域 ↔ 频域」的抽象概念拆解为 **11 个循序渐进的讲解步骤**，并配有
**3 段动画**和 **1 个交互式演示**，帮助学生直观理解傅里叶级数、傅里叶变换、
欧拉公式、采样定理，以及它们在脉冲傅里叶核磁共振中「两次傅里叶变换」的作用。

---

## 一、版本与运行环境

| 版本 | 位置 | 运行环境 |
| --- | --- | --- |
| MATLAB 版 | 仓库根目录（`*.m`） | MATLAB R2020a 及以上，需 Signal Processing Toolbox |
| GNU Octave 版 | [`GNU Octave/`](GNU%20Octave/) | GNU Octave 7.0 及以上（推荐 9.0+），无需商业授权 |

讲解文本在两个版本间共用同一份 `display_texts.csv`。

### MATLAB 版启动

```matlab
cd('本仓库目录');
runFourierTransformExplainer
```

### GNU Octave 版启动（Windows 一键）

双击 [`GNU Octave/start_explainer.bat`](GNU%20Octave/start_explainer.bat)，
脚本会自动定位 Octave、配置 Qt 绘图工具包与中文字体缓存并启动。

手动启动：

```octave
cd('本仓库/GNU Octave');
run_fourier_explainer_octave
```

Octave 版详细安装与调试说明见 [`GNU Octave/README_Octave.md`](GNU%20Octave/README_Octave.md)。

---

## 二、功能一览

**11 个讲解步骤**

1. 时域与频域的基本概念
2. 傅里叶级数：正弦波叠加逼近方波
3. 谐波叠加的收敛过程与吉布斯现象
4. 信号的频率、振幅、相位
5. 欧拉公式与旋转向量
6. 复指数形式与正负频率
7. 傅里叶变换的运算原理（旋转探针）
8. 采样定理——完全采样与混叠
9. 第一次傅里叶变换——射频脉冲
10. 第二次傅里叶变换——FID 信号
11. 总结——傅里叶变换的意义

**动画与交互演示**

- 级数分解动画、旋转圆动画（步骤 2）
- 采样定理与混叠交互演示（步骤 8，可拖动滑块改变 f0 与 fs）
- FID 信号与傅里叶变换 3D 动画（步骤 10）

**界面功能**

- 左侧控制面板（步骤导航、学习指南、步骤说明、操作说明）
- 中间原理展示区（多子图），底部核心要点汇总
- 可拖动分隔条调整左右宽度比例，窗口缩放时自动调整布局
- 子图可单独导出为图片（MATLAB 版）／`print` 导出（Octave 版）

---

## 三、目录结构

```
.
├── runFourierTransformExplainer.m      # MATLAB 版启动脚本
├── FourierTransformExplainer.m         # MATLAB 版主程序
├── SamplingAliasingDemo.m              # 采样混叠交互演示（MATLAB）
├── FourierSeriesAnimation.m            # 级数分解动画
├── FourierCircleAnimation.m            # 旋转圆动画
├── FIDFourierTransformAnimation.m      # FID 3D 动画
├── BaseAnimation.m / AppConstants.m    # 动画基类与全局常量
├── display_texts.csv                   # 全部讲解文本
├── NMR傅里叶变换原理讲解器-使用说明.docx/.pdf   # 图文使用说明
└── GNU Octave/                         # GNU Octave 兼容版
    ├── start_explainer.bat             # Windows 一键启动
    ├── run_fourier_explainer_octave.m  # 启动脚本
    ├── fourier_explainer_octave.m      # 主程序
    ├── oct_step_01.m … oct_step_11.m    # 11 个讲解步骤
    ├── sampling_aliasing_demo_octave.m # 采样混叠交互演示
    ├── *_anim_octave.m                 # 3 段动画
    ├── octave_env_check.m              # 环境自检
    ├── octave_selftest.m               # 无界面渲染自检
    ├── display_texts.csv               # 讲解文本
    └── README_Octave.md                # Octave 版安装与调试说明
```

---

## 四、使用说明文档

仓库包含一份图文并茂的使用说明（28 页，含各步骤界面截图）：

- `NMR傅里叶变换原理讲解器-使用说明.docx`（可编辑）
- `NMR傅里叶变换原理讲解器-使用说明.pdf`（直接阅读 / 打印）

---

