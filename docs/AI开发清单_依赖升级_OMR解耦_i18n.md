# AI 开发任务清单：全量依赖升级、OMRChecker 解耦、i18n 与 GitHub 发布准备

编写日期：2026-09-11。交付对象：接手实施的 AI 开发助手。

## 1. 用户目标与任务范围

用户计划公开发布该项目，希望处理的不只是 Python 3.12，而是整个项目的旧依赖。请完成：

- [ ] 盘点全部直接依赖、传递依赖、开发测试依赖、打包工具和平台工具链，升级至实施当日核实的最新稳定版本；遇到真实兼容性限制时列明例外，不得默默维持旧版本。
- [ ] 评估并实施脱离 OMRChecker，保留 Windows 纸质答题卡阅卷功能及人工确认流程。
- [ ] 完成应用国际化基础和首批语言迁移。默认首批语言按简体中文、英文实施；这是交接建议，不代表用户已经指定完整语言列表，开工时可简短询问是否调整，不影响独立的依赖工作。
- [ ] 完成双端回归、可复现构建、文档及 GitHub CI 更新。

这是一项开发执行任务，不要仅提交分析报告，也不要把目标缩减成修改几个版本号。不得为了追求“最新版”删除现有能力或改变评分、数据与同步规则。

## 2. 开工入口与约束

工作区：`<workspace>`（按本机实际路径替换）。

唯一应用 Git 仓库：`<workspace>/personal_exam_app`。

先完整阅读工作区根目录 `AGENTS.md`，再阅读：

1. `personal_exam_app/README.md`
2. `personal_exam_app/docs/github-readiness.md`
3. `personal_exam_app/docs/architecture.md`
4. `personal_exam_app/docs/validation.md`
5. `personal_exam_app/docs/题库生成要求.md`
6. `personal_exam_app/THIRD_PARTY_NOTICES.md`

当前用户的依赖现代化、OMR 解耦和 i18n 目标优先于旧文档中“必须只用 OMRChecker”“全部文案硬编码中文”等历史实现约定。其他业务和数据边界继续有效。

- [ ] 开始前读取 Git 状态和当前文件，不覆盖他人或上一轮已完成的修改。
- [ ] 当前仓库仍无首次提交，241 个文件已暂存，尚无远端及可用作者身份；这是交接时状态，必须重新核对。不要执行 reset/clean 丢弃暂存内容，不猜测姓名或邮箱。
- [ ] 不原地覆盖 `.tooling`、`.android-toolchain`、`.android-user` 中的现有工具链；新版本在独立目录安装并允许构建脚本显式选择。若确需替换现有工具链，先说明具体必要性。
- [ ] 不修改上级正式题库、旧交接文档，不访问 Anki/旧 ExamFlow，不读取或写入正式运行数据库来做测试。
- [ ] 使用内置 15 题包、内存数据库、临时隔离目录；旧数据库兼容性用合成旧版本数据库或隔离副本验证。
- [ ] 保留 Windows 题库写入职责和 Android 题库只读边界；不恢复 Android 拍照阅卷。
- [ ] 保留作答事件不可变、事务内事件/聚合/outbox 一致、幂等重放、冲突拒绝、未答不写事件等不变式。
- [ ] 不自动部署 Supabase、不操作正式云数据、不安装覆盖用户手机应用、不推送或创建公开仓库。设备安装、真实云验证和发布在目标明确且获授权后进行。
- [ ] 不引入 AI 题目服务、不扩展 iOS/Web，不做与本任务无关的架构重写。
- [ ] `.ps1` 保持 UTF-8 BOM；中文 `.bat` 保持 GBK、CRLF，不添加 `chcp`。

## 3. 已有成果：必须保留，不要重复实现

2026-09-11 的 GitHub 准备已完成以下修改：

- `lib/domain/bank_identity.dart`：外部 bank_id 的目录组件校验；导入和云媒体落盘入口已接入，防止路径穿越。
- `lib/config/supabase_config.dart`：移除个人云端硬编码默认值，支持可选 dart-define；设置页保存值优先。
- `tool/build_windows_release.ps1`：正常发布新增 analyze 关卡。
- `test/pdf_print_integration_test.dart`：Poppler 使用 `-singlefile`，修复输出文件名假设。
- README、`.gitignore`、`.gitattributes`、GitHub Windows CI 和公开准备报告已建立。

本轮交接之前实际验证：analyze 无问题、90 项 Flutter 测试全通过（含真实生成 PDF 和渲染、无跳过）、1 项 Python 几何契约单元测试通过、Windows release 编译成功。

这些是旧版本基线，不是升级后验收结果。没有在该轮重打 sidecar、生成新 dist、验证 Android 真机、真实纸张 OMR、真实云同步或 GitHub 托管 CI。

## 4. P0：建立全量依赖清单与升级基线

### 4.1 必须覆盖的依赖面

| 类别 | 清单入口 / 当前已知值 | 实施要求 |
| --- | --- | --- |
| Flutter / Dart | 本地 Flutter 3.44.7、Dart 3.12.2；pubspec SDK 约束 | 核实最新 stable；Dart 与 Flutter 配套升级，不独立拼装不兼容版本 |
| Dart 运行依赖 | sqlite3、path、archive、crypto、uuid、html、markdown、qr、image、http | 读取 pubspec.lock 的实际版本，不能仅把 `^` 下限当安装版本 |
| Dart 开发依赖 | flutter_test、flutter_lints、zxing2，及其传递依赖 | 升级并适配 API、lint 和测试；不直接关闭检查过关 |
| Python | 当前构建默认固定 Python 3.12 路径 | 目标标准 CPython 3.14 的最新稳定补丁版本；不默认使用预发布或 free-threaded 变体 |
| Python 直接依赖 | `tool/omrchecker_bridge/requirements.lock` | 分辨实际需要与 OMRChecker 遗留，删除不用的包，对保留的包升级 |
| Python 传递依赖 | `tool/omrchecker_bridge/constraints.lock` | 在干净环境重新解析锁定，验证相容性，不逐行盲目替换 |
| Python 打包 | PyInstaller、hooks-contrib、setuptools 等 | 验证 Python 3.14 支持、Windows wheels、冻结后 DLL 收集与启动 |
| Android | AGP 9.0.1、Kotlin 声明 2.3.20、Gradle 9.1.0、JDK 17、SDK/NDK | 以当前构建文件和工具链为准；核实各项最新稳定版及 Flutter 兼容矩阵，确认 Kotlin 声明是否实际参与构建 |
| Windows | CMake、MSVC、Windows SDK、Flutter runner/native assets | 核实有效版本；按新版 Flutter 要求适配，不破坏自建通道和 sqlite3 原生资产 |
| CI | checkout、flutter-action、setup-python 及 runner 镜像 | 核实当前稳定发行版，升级工作流，与本地构建保持一致 |
| 外部工具 | Edge/Chrome、Poppler、uv（如用于构建） | 记录最低要求和实测版本，避免把本机工具当应用内置能力 |
| 第三方源码 | `third_party/OMRChecker` | 执行解耦及来源核对，不机械更新到新上游后再删除 |

### 4.2 版本选择规则

- [ ] 从官方发布页、pub.dev、PyPI、官方兼容矩阵核实版本；为每项记录查询日期和来源链接。
- [ ] 最新版以实施当日为准，不以本文、旧文档或模型记忆为准。先记录稳定版快照，不在开发期间无限追逐新发行版。
- [ ] 区分当前声明范围、实际锁定版本、上游最新稳定版、最终采用版本。
- [ ] “当前约束下可升级”不等于“最新”：需要检查 major 版本并完成必要适配。
- [ ] 对无法升级至最新的包，记录具体上游限制、解析报错或测试证据、可用替代方案和下一步；不得只写“为稳定暂不升级”。
- [ ] 不使用 dependency_overrides、忽略 pip 冲突、跳过测试来掩盖不兼容。SDK 自带或锁定包的例外须解释。
- [ ] 删除不再需要的依赖；无发行包/已停止维护的必要依赖需要评估维护中的替代库，避免为替换而扩大范围。
- [ ] 为各个生态生成可复现锁文件；同一构建不能每次临时拉取未固定的 latest。
- [ ] 输出 `docs/dependency-upgrade-report.md`，表格列：组件、当前实际版本、最新稳定版、最终版本、保留/删除/替换、兼容依据、来源与日期、验收结果。

## 5. P1：脱离 OMRChecker，保留纸质阅卷

### 5.1 已发现的实际情况

`tool/omrchecker_bridge/omrchecker_bridge.py` 当前约 500 行，直接使用 OpenCV、NumPy 和标准库。`run()` 从约第 397 行开始，内部执行定位、透视校正、气泡位置修正和选项判定；本次静态阅读未发现 OMRChecker 模块调用。

然而 `build_sidecar.ps1` 仍检查上游 PINNED_COMMIT、安装旧依赖，并通过 PyInstaller `--add-data` 携带整个 OMRChecker。Windows 发布脚本又复制上游源码与许可证。当前“名称和打包依赖”与“实际算法调用”不一致。

### 5.2 实施清单

- [ ] 完整检查静态导入、动态导入、资源读取、模板字段、构建和运行路径；证明实际是否需要上游模块。
- [ ] 核对本地算法来源：是否从 GPL 代码复制、翻译或改写。没有 import 只能证明未直接调用，不能证明不存在衍生代码关系。无法确认的部分明确列出，不擅自改许可。
- [ ] 对允许独立使用的代码保留；需要替换的受限代码依据功能规范独立实现，不靠改名或删除版权声明处理。
- [ ] 优先保留现有 Python + OpenCV 独立识别进程；不默认重写成 C++ 或纯 Dart。
- [ ] 保持图片输入、版本化 JSON 输出、页四边形、气泡坐标、题号对应关系和人工复核界面契约。
- [ ] 保持二维码/定位点/ABCDE 表头/答题卡几何常量的一致性；不要因解耦改变现有打印坐标。格式必须变化时才引入显式版本和旧格式行为说明。
- [ ] 清理上游源码、上游打包输入、固定提交检查、未使用 Python 包；保留必要 OpenCV/NumPy/打包工具及其相容传递依赖。
- [ ] 统一文件名、类名、EXE 名称、日志和 UI 文案；删除残留 OMRChecker 表述，但不要无意义地改业务接口。
- [ ] 清理构建产物中的旧上游源码、旧 EXE 和依赖，确认新发行包没有因为增量构建混入旧材料。
- [ ] 更新 THIRD_PARTY_NOTICES 和对应许可文件。项目整体许可证仍待用户决定，禁止擅自选择 MIT、Apache 或 GPL。
- [ ] 当前 `confidence` 固定为 0.0，不应展示为有效概率；明确其语义。暂不实现可信置信度时保留人工核验要求，不捏造准确率。

### 5.3 OMR 验收

- [ ] 在不包含 `third_party/OMRChecker` 的干净构建目录中，完成构建、启动、扫描；仅 grep 无命中不足以验收。
- [ ] 使用真正的 OpenCV/NumPy 跑合成图测试，区别于当前将 cv2/numpy 替换为空模块的几何契约单元测试。
- [ ] 覆盖空白、单选、多选、满涂、浅涂、擦除、旋转/透视、阴影、缺失/重复定位点、错误题号、错误模板和图片格式。
- [ ] 有真实纸张样本时逐题对照人工标注，分别报告误选、漏选和拒识；没有样本则标为未验收，不用合成测试代替。
- [ ] 取消、超时、进程失败或结果无效不写作答事件；人工修改并确认后才按原事务提交。
- [ ] 在未安装系统 Python 的干净 Windows 环境验证完整发行包。如果没有可用环境，明确该项未验收并提供可执行步骤。

## 6. P2：升级保留依赖及工具链

- [ ] Python：独立 3.14 环境；更新保留依赖与锁文件，运行 pip check、单元测试、真实图像测试、PyInstaller 构建与冻结后调用。
- [ ] 不将旧 `runtime-build` 当新环境复用；避免旧 wheel 和 DLL 污染结果。只清理已经核对位于本任务构建目录内的文件。
- [ ] Flutter/Dart：升级 SDK、SDK 约束、全部直接与传递包，完成破坏性 API 适配。
- [ ] sqlite3 升级专项检查：Windows DLL、NativeAssetsManifest、Android native assets、WAL、事务和隔离旧库兼容性。
- [ ] archive/image/markdown/html/qr 升级专项检查：ZIP 导入校验、媒体路径保护、Markdown/PDF 输出、答题卡二维码与定位几何。
- [ ] Android：根据官方兼容矩阵更新 AGP/Gradle/Kotlin/JDK/SDK/NDK，保留原 applicationId 与 MethodChannel。
- [ ] Windows：保留 UTF-8 原生编译、关闭窗口拦截、文件选择、剪贴板取图通道。
- [ ] 构建脚本支持显式工具路径或可发现的标准安装位置，去掉特定用户账户的 Python 路径；保持旧环境可用直至新环境验证成功。
- [ ] CI 与文档使用最终选定版本，不留下旧 3.12 和旧锁文件互相矛盾的入口。

## 7. P3：i18n 实施清单

当前 `lib/` 静态扫描约 22 个文件、753 行含中文，包含注释和重复字符串，不是准确翻译条目数。

- [ ] 使用 Flutter 官方 flutter_localizations、ARB、gen-l10n，按最终 Flutter 版本核实生成方式，不引入另一套状态管理或路由库。
- [ ] 建立简体中文与英文资源，支持跟随系统和手动选择，保存本地语言偏好；不把语言设置强制同步到另一设备。
- [ ] 覆盖所有页面、弹窗、按钮、空状态、工具提示、设置、关闭确认及识别复核。
- [ ] 参数化动态文案，处理数量/单复数/日期/数字，避免字符串拼接和将完整中文句子作为资源键。
- [ ] 服务层错误与导入校验改为可本地化的消息标识和参数，技术诊断详情保留；不要把 BuildContext 引入数据库层。
- [ ] 本地化 Markdown、PDF、答题卡和导出文件的用户可见标签。界面语言与导出语言采用明确规则并记录，不自动翻译题目内容。
- [ ] 字体配置加入合理回退；检查 Windows、Android 的中文和英文显示，检查英文长文本溢出及大字号布局。
- [ ] 保持数据库表列、同步 JSON 键、事件 ID、题目 ID、内部枚举值稳定；不批量翻译历史记录。
- [ ] 保持中文题库契约兼容；需要英文导入表头时添加别名，不删除中文支持。
- [ ] 题干、选项、解析和用户笔记保持原文；不接入机器翻译或云翻译服务。
- [ ] 处理本地原生窗口/文件选择提示的语言边界；系统自带文案由系统语言控制的情况需说明。
- [ ] 为两种语言验证关键流程，并检查 missing translation、占位符一致性、语言切换重启持久化、双端窄屏与 PDF 分页。

## 8. P4：统一验收与发布准备

- [ ] 基线回归至少保留现有 90 项 Flutter 测试覆盖，不以删除测试、扩大 skip 或放宽断言消除失败；合理变更测试时解释原因。
- [ ] 静态分析、全量 Flutter 测试、Python 单元及真实依赖图像测试分别报告。
- [ ] Windows release 完整打包，验证 sqlite3 和 OMR 运行时均可用；不能仅编译 Flutter EXE 就宣布发布成功。
- [ ] Android APK 构建成功；仍为测试签名时明确标注，不自行创建或提交正式签名密钥。
- [ ] 双端实际运行、真实纸张、真实云同步分别记录；条件不足的项目标待验收，并交付样本/操作/预期结果说明。
- [ ] 在干净源码目录或克隆中重建，验证不依赖未跟踪文件、维护者缓存或个人云项目。
- [ ] GitHub CI 覆盖 Windows 分析/测试/编译、Android 编译，以及独立 OMR 构建/测试；不自动推送 Release 或部署云端。托管 CI 必须实际运行才可声明通过。
- [ ] 更新 README、architecture、validation、github-readiness、第三方声明；必要时更新根 AGENTS.md 的过时工具版本和实现描述，不额外创建第二份 AI 开发指南。
- [ ] 新发行版本仍以 pubspec.yaml 为唯一来源，Windows/Android/UI 版本一致；重新生成的 dist 应有 SHA256。
- [ ] 审查最终索引及包内容：无管理密钥、会话、用户数据库、正式题库、签名材料、旧 OMRChecker 残留；锁文件和必要许可可追溯。

## 9. 实施顺序与交付物

建议顺序：基线和清单 → OMR 来源核对与最小解耦 → Python 精简升级 → Flutter/Dart 升级 → Android/Windows 构建适配 → i18n → 双端及发行回归 → 文档和 CI 收尾。

若 Flutter 最新稳定版是其他依赖升级的前置条件，可以调整次序，但每个阶段保留可定位的差异和验证结果。不要同时改算法阈值、图像库版本、答题卡几何和全部 UI 后才首次测试。

必须交付：

1. 实际代码、最终锁文件、构建入口、CI 和必要许可证材料。
2. `docs/dependency-upgrade-report.md`：逐项新旧版本、删除项、最新版本例外及依据。
3. `docs/omr-decoupling.md`：来源核对、去除范围、剩余许可、协议和图像验收结果。
4. ARB、语言切换和使用说明；资源缺失检查与界面/导出证据。
5. 更新后的验证记录：命令、版本、成功/失败/跳过数量、产物路径和未验收边界。
6. 一份明确的剩余事项清单；许可证、作者身份、远端、正式签名等用户尚未决定的事项不得伪造。

## 10. 可直接发送给接手 AI 的启动提示词

> 请在 `<workspace>` 工作区执行 `personal_exam_app/docs/AI开发清单_依赖升级_OMR解耦_i18n.md`。先阅读根 AGENTS.md 和当前 Git 状态，保留已有 GitHub 准备修改。目标是升级整个项目的直接/传递/开发依赖及必要工具链到实施当日最新稳定版本，核实并解除 OMRChecker 依赖、保留 Windows 阅卷，完成 i18n 和双端构建回归。Python 目标为 3.14 最新稳定补丁版，不要只升级 Python 或只改版本号。每个无法采用最新版的例外必须给出具体证据。现有 OMR bridge 看起来已经直接使用 OpenCV/NumPy，但打包仍携带 OMRChecker，需核对调用及代码来源后处理。许可证尚未决定，禁止擅自换许可证或删除应保留的版权声明。首批语言默认按简体中文和英文规划，若需确认语言范围可简短询问，同时推进独立的依赖工作。不操作正式数据、不覆盖现有工具链、不恢复 Android 阅卷、不擅自推送或部署。完成代码、锁文件、构建、测试和报告；把实际通过与尚未验收明确分开。
