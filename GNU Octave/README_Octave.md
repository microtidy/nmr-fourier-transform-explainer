# 傅里叶变换原理讲解器 · GNU Octave 版

本目录是《NMR 傅里叶变换原理讲解器》的 **GNU Octave 兼容实现**，供没有 MATLAB 场地授权的
高校师生使用。功能与 MATLAB 版对应：11 个讲解步骤、学习指南、步骤说明、核心要点汇总、
可拖动分隔条、采样混叠交互演示，以及 3 段动画演示。

---

## 一、目录内容

| 文件 | 说明 |
| --- | --- |
| `run_fourier_explainer_octave.m` | 启动脚本（对应 MATLAB 版 `runFourierTransformExplainer.m`） |
| `fourier_explainer_octave.m` | 主程序：界面布局、步骤切换与文本加载 |
| `oct_step_01.m` … `oct_step_11.m` | 11 个讲解步骤的绘图函数 |
| `sampling_aliasing_demo_octave.m` | 采样定理与混叠交互演示窗口 |
| `fourier_series_anim_octave.m` | 傅里叶级数分解动画 |
| `fourier_circle_anim_octave.m` | 欧拉公式旋转圆动画 |
| `fid_anim_octave.m` | FID 信号与傅里叶变换动画 |
| `octave_env_check.m` | 运行环境自检与配置 |
| `octave_selftest.m` | 无界面自检：渲染全部步骤到 PNG，用于调试 |
| `start_explainer.bat` | Windows 一键启动脚本（自动配置环境） |
| `display_texts.csv` | 全部讲解文本（与 MATLAB 版相同） |
| `oct_*.m` | 兼容与辅助函数（网格定位、CSV 读取、中文标题、Signal 替代函数等） |

> 讲解文本统一放在 `display_texts.csv`。若修改文字，两个版本会同步生效；
> 若该文件缺失，程序会自动使用内置的简化文本。

---

## 二、环境要求

* **GNU Octave 7.0 或更高版本**（推荐 9.0 及以上；本机已配置 11.3.0）。
* 绘图工具包：**qt**（用于中文显示与导出图片）。`octave-gui` 自带 qt；
  `octave-cli` 只有 fltk/gnuplot，无法正常导出，请使用 GUI 版。
* **Signal 包（可选）**：用于 `square / sawtooth / sinc / findpeaks`。
  本目录已内置替代实现（`oct_square.m`、`oct_sawtooth.m`、`oct_sinc.m`、`oct_findpeaks.m`），
  因此**不安装 Signal 包也能完整运行**。

### 本机已安装的 Octave

```
D:\Tools\GNU Octave\octave-11.3.0-w64\mingw64\bin\octave-gui.exe
```

启动脚本会自动定位该路径；如安装在其他位置，可设置环境变量 `OCTAVE_HOME`
指向 Octave 安装目录，或把 `octave-gui.exe` 加入系统 `PATH`。

---

## 三、启动方法

### 方法 1：一键启动（推荐，Windows）

双击本目录下的 `start_explainer.bat`。脚本会自动完成：

1. 定位 `octave-gui.exe`；
2. 设置 Qt 插件路径 `QT_PLUGIN_PATH` / `QT_QPA_PLATFORM_PLUGIN_PATH`（启用 qt 绘图工具包）；
3. 设置字体缓存目录 `XDG_CACHE_HOME`（避免中文用户名导致 fontconfig 缓存不可写）；
4. 以本目录为工作目录启动讲解器。

### 方法 2：在 Octave 中手动启动

打开 GNU Octave（GUI 版），先切换到本目录，然后运行：

```octave
cd('本目录的完整路径');
run_fourier_explainer_octave
```

也可先执行环境自检：

```octave
octave_env_check      % 检查版本 / 工具包 / 文本 / 绘图能力
```

---

## 四、界面与操作

与 MATLAB 版一致：

* **左侧控制面板**：11 个步骤按钮、“学习指南”“步骤说明”按钮、操作说明文本框；
* **中部原理展示区**：当前步骤的原理图（多个子图）；
* **底部核心要点汇总**：当前步骤的关键结论；
* **中间分隔条**：按住拖动可调整左右宽度比例；
* **缩放窗口**：面板与子图会随窗口自动调整。

### 查看动画与交互演示

* 步骤 2 底部：`级数分解动画`、`旋转圆动画`；
* 步骤 8 底部：`启动采样混叠交互演示`（拖动滑块改变 f0 与 fs）；
* 步骤 10 底部：`启动 FID 3D 动画演示`。

---

## 五、调试与自检

### 5.1 无界面自检（推荐先运行）

在 Octave 中运行：

```octave
octave_selftest
```

它会把 11 个步骤、采样交互演示与 3 段动画各渲染一帧，输出到
`GNU Octave/selftest_out/` 目录，并在命令行打印每一步是否成功：

```
  步骤  1 : OK
  ...
  步骤 11 : OK
  采样交互演示 : OK
  anim_series : OK
  anim_circle : OK
  anim_fid : OK
  自检完成：失败项 0 个。
```

用图片查看器打开 `selftest_out` 中的 PNG，即可确认中文、坐标轴与各子图是否正常。

### 5.2 常见问题与解决

| 现象 | 原因与解决办法 |
| --- | --- |
| `graphics_toolkit: qt toolkit is not available` | 使用了 `octave-cli`。请改用 `octave-gui`（或运行 `start_explainer.bat`）。 |
| 图中中文显示为方框或错位 | 未设置中文字体或缓存不可写。软件已自动设置 `Microsoft YaHei`；如仍异常，请运行 `start_explainer.bat` 以设置 `XDG_CACHE_HOME`。 |
| `Fontconfig error: No writable cache directories` | 中文用户名导致字体缓存路径不可写。设置环境变量 `XDG_CACHE_HOME` 指向纯英文路径即可（启动脚本已处理）。 |
| `'square' / 'sawtooth' / 'sinc' / 'findpeaks' undefined` | 未安装 Signal 包。本目录已内置同名替代函数（`oct_*`），正常运行不会报错；如仍报错，请确认本目录已加入 Octave 路径。 |
| 动画窗口点击“开始动画”后窗口短暂无响应 | Octave 无 `timer` 类，动画采用循环逐帧刷新实现。动画期间界面会持续刷新，可用“暂停/继续”。 |
| 导出图片 | 在 Octave 命令行用 `print(fig, '文件名.png', '-dpng', '-r150')`；`octave_selftest` 已演示该用法。 |
| 文字乱码（文件里） | 请保持 `display_texts.csv` 与所有 `.m` 文件为 **UTF-8** 编码。 |

### 5.3 环境自检脚本说明

`octave_env_check` 会依次检查并打印：

1. Octave 版本与运行平台；
2. 可用绘图工具包（并尝试切换到 qt）；
3. 是否安装 Signal 包（未安装则提示使用内置替代）；
4. 讲解文本 `display_texts.csv` 是否存在；
5. 一次真实的绘图导出测试（结果保存到系统临时目录）。

### 5.4 环境变量（一键脚本已自动设置）

```bat
set QT_PLUGIN_PATH=<Octave>\mingw64\qt6\plugins
set QT_QPA_PLATFORM_PLUGIN_PATH=<Octave>\mingw64\qt6\plugins\platforms
set XDG_CACHE_HOME=<可写目录>
```

---

## 六、与 MATLAB 版的差异

* 本版用**过程式函数**实现（MATLAB 版为主类 `FourierTransformExplainer`），
  对使用者而言操作方式完全一致。
* Octave 的 `print` 不能导出嵌在 uipanel 内的坐标轴，因此绘图坐标轴直接放在
  figure 上，uipanel 仅作背景与标题；交互显示不受影响。
* Octave 无 `timer` 类，动画用循环逐帧刷新实现。
* 未使用 `axtoolbar`（Octave 不支持），导出请用 `print` 命令。
* 步骤 4 在 Octave 版采用 2 行 × 4 列布局（MATLAB 版为 4 行 × 2 列），
  以获得更充裕的垂直空间、避免文字重叠；内容与顺序不变。

---

## 七、快速开始（三步）

1. 双击 `start_explainer.bat`（或按“方法 2”手动启动）；
2. 若要确认环境是否正常，先在 Octave 中运行 `octave_env_check`，再运行 `octave_selftest`；
3. 点击左侧步骤按钮，按 1 → 11 的顺序学习，并在步骤 2 / 8 / 10 中体验动画与交互演示。
