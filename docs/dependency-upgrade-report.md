# 依赖升级报告

核实日期：2026-09-11。范围为全项目直接依赖、传递依赖、开发测试依赖、打包工具与双端平台工具链。
升级原则：以实施当日核实的最新稳定版为目标；与 Flutter 官方兼容矩阵或上游支持策略冲突时，
保留对齐版本并在此记录具体证据，不默默维持旧版本。

## 1. 版本核实来源

| 项 | 来源 | 核实日期 |
| --- | --- | --- |
| Flutter stable | `flutter --version`（本地 SDK 3.47.1，2026-08-19 发布）与 [Flutter SDK 发布页](https://docs.flutter.dev/release/release-notes) | 2026-09-11 |
| pub 包最新版 | `flutter pub outdated`（pub.dev 实时解析） | 2026-09-11 |
| Android Gradle Plugin | [AGP 9.4.0 发行说明](https://developer.android.com/build/releases/agp-9-4-0-release-notes) | 2026-09-11 |
| Gradle | [Gradle 9.7.1 发行说明](https://docs.gradle.org/9.7.1/release-notes.html)（9.8.0 尚为 RC，不采用） | 2026-09-11 |
| Kotlin | [Kotlin 发布页](https://kotlinlang.org/docs/releases.html)（2.4.20 stable；2.5.0 计划 2026-12） | 2026-09-11 |
| AGP 兼容要求 | [Gradle 插件兼容表](https://developer.android.com/build/releases/gradle-plugin)：AGP 9.4 需 Gradle ≥ 9.6.0、JDK ≥ 17、Build Tools 36.0.0 | 2026-09-11 |
| Flutter AGP/KGP 支持策略 | 本地 SDK 源码 `flutter-3.47.1/packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt`（warn 阈值：Gradle 9.1.0、AGP 9.0.1、KGP 2.3.20；error 阈值：Gradle 8.14.0、AGP 8.11.1、KGP 2.2.20、JDK 17） | 2026-09-11 |
| Python | [Python 3.14 更新日志](https://docs.python.org/3/whatsnew/3.14.html)（3.14.7，2026-08-05 发布，为 3.14 系列最新补丁） | 2026-09-11 |
| Python 包 | PyPI JSON API（numpy / opencv-python-headless / pyinstaller `info.version`） | 2026-09-11 |
| GitHub Actions | [actions/checkout](https://github.com/actions/checkout/releases) v6、[actions/setup-python](https://github.com/actions/setup-python) v6、[actions/setup-java](https://github.com/actions/setup-java/releases) v6.0.1（2026-09-09） | 2026-09-11 |

## 2. Flutter / Dart

| 组件 | 升级前 | 最新稳定版 | 最终采用 | 说明 |
| --- | --- | --- | --- | --- |
| Flutter SDK | 3.44.7 stable | 3.47.1 stable | **3.47.1** | 独立安装于 `.tooling/flutter-3.47.1`，旧目录 `.tooling/flutter` 未改动，保留回退 |
| Dart SDK | 3.12.2 | 3.13.1（随 Flutter 配套） | **3.13.1** | 与 Flutter 3.47.1 配套，不独立拼装 |
| pubspec `environment.sdk` | ^3.12.2 | — | **^3.13.0** | 配套约束 |

验收：`flutter analyze` 无问题；`flutter test` 全部通过；`flutter build apk --debug` 成功（详见 §8）。

## 3. Dart 依赖（pubspec.lock 实际锁定版本）

| 包 | 升级前锁定 | 最新稳定版 | 最终锁定 | 处理 |
| --- | --- | --- | --- | --- |
| sqlite3 | 3.5.2 | 3.5.2 | 3.5.2 | 保留（已最新） |
| archive | 4.1.0 | 4.2.0 | **4.2.0** | 升级 |
| html | 0.15.6 | 0.15.7 | **0.15.7** | 升级 |
| crypto | 3.0.7 | 3.0.7 | 3.0.7 | 保留 |
| uuid | 4.6.0 | 4.6.0 | 4.6.0 | 保留 |
| markdown | 7.3.1 | 7.3.1 | 7.3.1 | 保留 |
| qr | 4.0.0 | 4.0.0 | 4.0.0 | 保留 |
| image | 4.9.2 | 4.9.2 | 4.9.2 | 保留 |
| http | 1.6.0 | 1.6.0 | 1.6.0 | 保留 |
| path | 1.9.1 | 1.9.1 | 1.9.1 | 保留 |
| intl | （无） | 0.20.3 | **0.20.3** | 新增（i18n 基础） |
| flutter_localizations | （无） | SDK | **SDK** | 新增（i18n 基础） |
| flutter_lints（dev） | 6.0.0 | 6.0.0 | 6.0.0 | 保留 |
| zxing2（dev，仅测试） | 0.2.4 | 0.2.4 | 0.2.4 | 保留 |

`flutter pub outdated`（2026-09-11）确认：**直接依赖全部为最新**。传递依赖中的两个例外：

| 传递依赖 | 锁定 | 最新 | 例外依据 |
| --- | --- | --- | --- |
| material_color_utilities | 0.13.0 | 0.13.1 | 随 Flutter SDK 锁定（SDK 自带包），版本由 Flutter 3.47.1 工具解析结果决定，不能独立升级 |
| test_api | 0.7.12 | 0.7.14 | 同上（随 flutter_test SDK 锁定） |

原生资产相关传递包随 sqlite3 3.5.2 与新 SDK 上升（code_assets 2.0.0、hooks 2.2.0、record_use 1.1.1、native_toolchain_c 0.19.4）。

sqlite3 升级专项检查：Windows 发行包含 `sqlite3.dll` 且 `NativeAssetsManifest.json` 映射校验由发布脚本强制（`tool/build_windows_release.ps1`）；WAL 模式、事务与隔离测试在 `flutter test` 覆盖；Android 侧经 native assets 构建验证（APK 编译成功）。

## 4. Python / OMR sidecar

| 组件 | 升级前 | 最新稳定版 | 最终采用 | 说明 |
| --- | --- | --- | --- | --- |
| Python | 3.12.13（uv 管理，构建脚本硬编码用户路径） | 3.14.7 | **3.14.7** | 独立 venv `.tooling/py3147-sidecar-venv`；非预发布、非 free-threaded |
| numpy | 旧锁（随 OMRChecker 遗留） | 2.5.3 | **2.5.3** | PyPI 最新 |
| opencv-python-headless | 旧锁 | 5.0.0.93 | **5.0.0.93** | PyPI 最新 |
| pyinstaller | 旧锁 | 6.22.2 | **6.22.2** | PyPI 最新，支持 Python 3.14 |
| 传递依赖 | 34 个包 | — | **9 个包** | 在 3.14.7 干净环境重新解析（`constraints.lock`），剔除 OMRChecker 遗留 |
| 删除的包 | 旧 requirements 共 10 个直接包 | — | — | OMRChecker 解耦后不再需要（PDF 阅读库 PyMuPDF/Fitz 明确禁入并有构建期检查） |

验收：bridge 单元测试 9/9 通过（含 6 项真实 OpenCV/NumPy 合成整卡识别）、`pip check` 无冲突、PyInstaller 冻结 EXE `--self-test` 通过（详见 `docs/omr-decoupling.md` §5）。

## 5. Android 工具链

| 组件 | 升级前 | 最新稳定版 | 最终采用 | 说明 |
| --- | --- | --- | --- | --- |
| Android Gradle Plugin | 9.0.1 | 9.4.0（2026-09） | **9.4.0** | 见 §5.1 例外说明 |
| Gradle | 9.1.0 | 9.7.1（9.8.0 为 RC 不采用） | **9.7.1** | wrapper 升级；发行包缓存独立新增，未动旧 9.1.0 |
| Kotlin (KGP) | 2.3.20 | 2.4.20 | **2.4.20** | 见 §5.1 |
| JDK | 17.0.20+8 | — | **17（不变）** | AGP 9.4 最低/默认 JDK 17；`.android-toolchain` 未改动 |
| SDK / Build Tools | android-35/36 + build-tools 34/35/36 | build-tools 36.0.0 | 满足（已装 36.0.0） | AGP 9.4 默认 Build Tools 36.0.0 |
| NDK | 28.2.13676358 | 28.2.13676358（AGP 9.4 默认值相同） | 不变 | 项目无 NDK 原生代码，仅 Flutter 默认声明 |

### 5.1 已知边界（不是"为稳定不升级"，是上游实测范围声明）

Flutter 3.47.1 的官方支持策略（SDK 源码 `DependencyVersionChecker.kt`，2026-09-11 核对）将
Gradle 9.1.0 / AGP 9.0.1 / KGP 2.3.20 列为 **warn 阈值**（超出仅提示未经 Flutter 测试，不阻断），
error 阈值远低于当前值。本次采用最新稳定版（AGP 9.4.0 / Gradle 9.7.1 / Kotlin 2.4.20）后，
`flutter build apk --debug` 实测成功。若 Flutter 后续版本上调官方对齐值，无需回退本组版本。
Kotlin 声明的实际参与度：项目唯一 Kotlin 代码为模板 `MainActivity.kt`，KGP 版本声明参与
Gradle 插件解析，但不涉及语言特性迁移。

## 6. Windows 工具链

| 组件 | 版本 | 说明 |
| --- | --- | --- |
| Visual Studio Build Tools 2022 | 17.14.21（2025-11），MSVC + Win10 SDK 10.0.26100.0 | 满足 Flutter 3.47.1 Windows 桌面构建要求 |
| CMake | 随 VS / Flutter 分发 | 未单独升级 |
| Windows runner | Flutter 模板，`/utf-8` 编译保留 | 自建 MethodChannel、关窗拦截不受影响 |
| sqlite3 原生资产 | native assets（`sqlite3.dll`） | 发布脚本含映射校验 |

## 7. CI 与外部工具

| 组件 | 升级前 | 最新稳定版 | 最终采用 |
| --- | --- | --- | --- |
| actions/checkout | v6 | v6 | v6 |
| actions/setup-python | v6 | v6 | v6 |
| actions/setup-java | v6 | v6.0.1 | v6 |
| subosito/flutter-action | v2 | v2 | v2（flutter-version 3.47.1） |
| CI Python | 3.14 | 3.14（runner 解析最新 3.14.x） | 3.14 |
| Edge（PDF 集成测试） | 152.0.4191.66 | — | 本机记录，非应用内置能力 |
| Poppler（PDF 集成测试） | `.tooling/poppler` | — | 本机记录；CI runner 缺失时测试自动 skip |

注：CI 托管运行尚未实际执行（仓库未推送），见 §8 未验收。

## 8. 验收结果（2026-09-11 更新）

- `flutter analyze`（3.47.1）：无问题。
- `flutter test`（3.47.1）：**97/97 通过**（含 PDF 集成测试与新增 i18n/导出标签测试；
  PDF 测试需 poppler 在 PATH，`.tooling/poppler` 提供）。
- `flutter build apk --debug`（AGP 9.4.0 + Gradle 9.7.1 + Kotlin 2.4.20）：成功。
- Python bridge：9/9 测试通过、`pip check` 通过；发布脚本内 PyInstaller（Python 3.14.7 venv）
  冻结自检 `synthetic geometry checks passed`。
- Windows 完整发行包：`dist/个人刷题-Windows-x64-0.8.0.zip`（85,970,698 字节），
  SHA-256 `a8df3c7dd683938ccb28c9f0b61d21bca707367e81072a220ee6d03950846b26`；
  包内容 0 处 OMRChecker 残留，sidecar、sqlite3.dll、NativeAssetsManifest 映射、
  许可文件与桥接源码齐备。详细未验收边界见 `docs/validation.md` 2026-09-11 节。

## 9. 删除项汇总

| 项 | 处理 | 依据 |
| --- | --- | --- |
| `third_party/OMRChecker/`（GPL-3.0 上游源码） | 整目录删除 | OMR 解耦，见 `docs/omr-decoupling.md` |
| `tool/omrchecker_bridge/`（旧桥 + 旧锁文件） | 更名 `tool/paper_omr_bridge/` 并重写锁文件 | 同上 |
| 旧 requirements 中 7 个未使用直接包 | 删除 | 静态核对实际 import 面 |
| 构建脚本中 OMRChecker 源码校验/拷贝/许可证分发/固定 commit 检查 | 删除 | 同上 |
| 构建脚本中特定用户账户的 Python 3.12 硬编码路径 | 删除，改为 `-Python` 参数 + 独立 venv | 可移植性要求 |

## 10. 遗留与例外清单

1. material_color_utilities / test_api：Flutter SDK 锁定，无法独立升级（§3）。
2. Gradle 9.8.0、Python 3.14.8：尚为 RC / 未发布，不采用预发布版本。
3. GitHub 托管 CI 首次运行、真实纸张 OMR、真实云同步、Android 真机：未验收（条件不足，
   见 validation.md 未验收清单）。
4. Android release 仍为 debug 签名（正式签名密钥由维护者决定，不代创建）。
