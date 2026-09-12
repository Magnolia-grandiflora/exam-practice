# OMRChecker 解耦记录

## 2026-09-12 补充核查（当前状态）

工作目录中的上游代码此前已删除，但上游文件和旧桥接目录仍在 Git 初始暂存区。本次移除了这两个旧目录的索引记录；旧的“已从仓库删除”表述只适用于当时工作树。

现用接口改为 `WindowsOmrScanner`（`lib/services/windows_omr_scanner.dart`），新作答事件来源为 `paper_omr_scan`。当前工具、调用、测试和构建脚本去除旧项目名称；旧事件不会重写，保持原 payload/hash 与同步幂等性。以下历史记录保留原名称用于来源追溯。

本次重复运行 9 项 Python 契约/合成图测试通过。项目自有代码许可证已准备为 MIT，参见 [licensing.md](licensing.md)。源码与运行依赖清理不构成完整历史来源证明，也不改变旧版已分发材料原有的许可义务。

完成日期：2026-09-11。本文件回答三个问题：桥接代码是否真的不依赖 OMRChecker、
代码来源是否涉及 GPL 衍生、解耦后的契约与验收状态。

## 结论

- Windows 纸质答题卡阅卷功能保留，实现为一个**独立桥接进程**
  `tool/paper_omr_bridge/paper_omr_bridge.py`（发行包内为 `paper_omr_bridge.exe`），
  仅依赖 OpenCV（`opencv-python-headless`）、NumPy 与 Python 标准库。
- `third_party/OMRChecker` 上游源码已从仓库删除；构建与发布脚本不再读取、
  打包或校验该源码。
- 答题卡几何（`a4-omr-v4`）、二维码校验、人工确认后才写作答事件的流程**均未改变**；
  打印坐标与识别坐标不受本次解耦影响。

## 1. 依赖调用核对（为什么可以删除上游）

对旧 `tool/omrchecker_bridge/omrchecker_bridge.py`（约 504 行）做过完整静态核对：

- 导入面：`argparse`、`json`、`math`、`re`、`sys`、`pathlib`（标准库）+ `cv2` + `numpy`。
  无任何 `omrchecker`、`src`、`processors` 等上游模块导入，无动态 `importlib` 调用，
  无 `subprocess`/`os.system` 调用上游脚本。
- 资源读取：只读取调用方传入的 `template.json`（不读取上游 `config.yaml`、
  `inputs/`、`samples/` 等资源）。
- 模板契约：`_load_contract` 显式要求 `personal_exam_geometry` 字段并**拒绝**
  通用 OMRChecker 模板（`ValueError("a4-omr-v4 geometry contract is missing")`），
  因此不存在"隐式回退到上游模板引擎"的路径。
- 打包面：旧 `build_sidecar.ps1` 虽然用 `--add-data` 携带上游源码，但那只是
  PyInstaller 数据文件，冻结后的进程没有任何代码路径加载它；这属于
  "打包依赖"与"实际调用"的历史不一致，本次解耦即为此而做。

## 2. 来源核对（GPL 衍生风险评估）

OMRChecker 以 GPL-3.0 发布。仅"没有 import"不足以证明无衍生关系，因此做了
代码结构层面的比对：

- 桥接代码使用的技术路径与 OMRChecker 上游不同：桥接使用嵌套方框轮廓
  （`RETR_TREE` 子/孙层级）+ 四点单应 + `HoughCircles` 气泡圆环吸附 +
  分组仿射点阵拟合；上游 `OMRChecker/src` 未使用 `HoughCircles`，其
  `FeatureBasedAlignment.py` 虽也调用 `estimateAffine2D`，但用途是 ORB 特征
  匹配的整页对齐，与桥接的气泡点阵拟合在输入、输出与实现上均不同。
- 桥接中的项目专属契约（`personal_exam_geometry`、`a4-omr-v4`、
  `marker_centers`、`qN..qM` 标签解析）在 OMRChecker 上游源码中不存在。
- 双方共用的只有 OpenCV 公共原语（`findContours`、`getPerspectiveTransform`、
  `warpPerspective` 等）和通用的"定位点 → 透视校正 → 气泡采样"流程思想；
  流程思想不受版权保护，具体表达（代码结构、常量推导、错误处理、注释）为
  本项目独立实现。
- 残余不确定性：以上核对由静态阅读完成，未做过逐行历史考古（旧提交不可考，
  仓库无首次提交）。若维护者确认代码全部为本项目从零编写，可视为无衍生；
  在项目整体许可证确定前，本文件不做法律结论，也不新增或删除任何许可声明。

## 3. 解耦范围（本次改动）

| 项 | 处理 |
| --- | --- |
| `third_party/OMRChecker/` | 整目录删除 |
| `tool/omrchecker_bridge/` | 更名 `tool/paper_omr_bridge/`，模块名 `paper_omr_bridge.py` |
| 侧车 EXE | `omrchecker_bridge.exe` → `paper_omr_bridge.exe`（`windows_omr_checker.dart` 同步） |
| `build_sidecar.ps1` | 删除 PINNED_COMMIT 校验、上游路径与 `--add-data`；保留 PyMuPDF/Fitz 双重禁入检查；新增冻结后自检步骤 |
| `build_windows_release.ps1` | 删除上游源码校验/拷贝/许可证分发；新增旧产物清理（防止增量构建混入 OMRChecker 材料）；发行包附带桥接源码与两个测试文件 |
| Python 依赖 | `requirements.lock` 从 10 个直接包精简为 numpy / opencv-python-headless / pyinstaller；`constraints.lock` 在 Python 3.14.7 干净环境重新解析（transitive 从 34 个包降到 9 个） |
| 导出模板文件 | `omrchecker-template.json` → `omr-template.json`；导出清单 `engine` 值 → `paper-omr` |
| 答题卡 HTML/CSS 类名 | `omrchecker-*` → `omr-*`（纯展示层，识别不读取这些类名） |
| UI / 错误文案 | "OMRChecker …" → "答题卡阅卷 / 阅卷组件 …"（后续 i18n 迁移为资源键） |
| 数据层枚举 | 作答事件来源值 `omrchecker_scan` **保留不变**（内部枚举值稳定，不改历史数据语义） |
| 文档 | `THIRD_PARTY_NOTICES.md`、`README.md`、`docs/architecture.md` 同步更新 |

## 4. 输出契约（未变，兼容说明）

`paper_omr_bridge` 的命令行与 JSON 输出 schema 保持 `schema_version: 2` 不变：

- CLI：`--input <PNG/JPG/JPEG> --template <json> --output <json>`，`--self-test`。
- 输出字段：`schema_version`、`layout`、`source_size`、`page_quad`、
  `questions[].label/selected/confidence/bubble_quad`。
- `confidence` 语义澄清：本实现不估计选择概率，恒为 `0.0`。调用方（Dart 层）
  不得把它当真实概率展示；识别结果一律经人工确认后才写入作答事件。该字段
  保留在 schema 中是为了版本兼容，未来若实现真实置信度，将以显式 schema
  版本升级通告。

## 5. 验收结果（2026-09-11，合成图边界）

环境：Python 3.14.7（官方安装器，用户级目录）、numpy 2.5.3、
opencv-python-headless 5.0.0.93、PyInstaller 6.22.2（Windows x64）。

- `tool/paper_omr_bridge` 单元测试 9/9 通过，其中 6 项为**真实 OpenCV/NumPy**
  合成整卡测试（区别于旧版 mock 几何测试）：
  - 空白 / 单选 / 多选 / 满涂（ABCDE）混合识别正确；
  - 浅涂（灰度 170）不被误判为选中；
  - 透视拍照（模拟手机拍摄的非正视角缩放图）后 q1/q7/q20 识别正确；
  - JPEG 输入格式支持；
  - 缺失/重复定位点在自检中必须失败（`run_synthetic_geometry_checks`）。
- PyInstaller 冻结产物 `paper_omr_bridge.exe`（71.2 MB）生成成功，
  `--self-test` 通过，并对同一张合成整卡完成完整识别：q1=A、q7=C+D、
  q20=B、未涂题为空，JSON 输出与源码运行一致。
- 上述均为合成图结果，**不能替代**真实纸张验收；真实 A4 打印 + 手机拍摄 /
  扫描件的人工逐题对照仍是待验收项（见 `docs/validation.md`）。

## 6. 未验收 / 待办

- 真实 A4 纸张拍照 / 扫描件的 PC 阅卷逐题人工对照（误选 / 漏选 / 拒识率）。
- 在未安装系统 Python 的干净 Windows 环境验证完整发行包（本机验证环境
  含系统 Python，需要另找干净环境或虚拟机）。
- GitHub 托管 CI（含新增 `paper-omr-sidecar` job）首次实际运行验证。
- 项目整体许可证待维护者决定（见 `docs/github-readiness.md`）。
