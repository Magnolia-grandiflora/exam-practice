# 题序 · Exam Practice

<img src="docs/assets/icon.png" alt="题序应用图标" width="128" height="128">

**把历年真题和教辅题目，整理成有顺序的日常练习。**

[![Read in English](docs/assets/readme-en.svg)](README.md)

题序是一款围绕大量历年真题、习题册和教辅练习开展复习的刷题工具，面向应试备考。对于有明确考纲、常见题型和丰富练习资料的考试，例如职业资格考试、专业认证考试和升学考试，可以把分散的题目整理为自己的题库，持续练习与回顾。

“题”是备考积累的题目，“序”是使用这些题目的顺序：覆盖未见题、回顾错题，再通过组卷检验复习情况。每次作答留下记录，解析和出处随题保留，让下一轮练习有所依据。

应用支持 Windows 和 Android，界面可切换简体中文和英文，使用 Flutter + SQLite，离线即可使用。

无需账号或网络即可刷题。如果需要在设备之间同步进度，可以使用仓库附带的 SQL，部署自己的可选 Supabase 同步后端。

## 从备考资料到日常练习

1. **整理题库**：从有权使用的历年试卷和教辅资料中整理题目，尽量保留答案、解析、年份、章节和出处，转换为 ZIP、TSV 或 CSV 题库，在 Windows 上导入。
2. **覆盖未见题**：按年份、章节或考点筛选，逐步完成尚未练过的题目。通过答题记录了解覆盖情况，减少反复翻到熟悉题目的盲目练习。
3. **回顾错题**：覆盖练习池中的未见题后，再回顾错题和解析，结合答题历史回到教材或教辅中补充复习。
4. **组卷检验**：按需要设置题型数量和评分规则，计时作答并查看结果，也可以导出试卷或错题集进行纸面练习。

Word、PDF 和扫描版教辅需要先转换为[题库格式](docs/题库生成要求.md)再导入，应用目前不内置从这些原始文档中自动提取题目的功能。仓库提供测试题库，具体考试内容由使用者准备。

## 主要功能

- **按顺序练习**：优先覆盖未见题，再回顾错题，支持答题历史、筛选和统计。
- **自定义组卷**：按题型设置题数，保存草稿、记录用时，通过题号导航切换题目。
- **自定义试卷评分**：设置单选、多选分值，少选部分分和错选处理方式；每份试卷保存自己的评分策略。
- **支持问答题**：作答文本随试卷保存；问答题不自动判分，也不计入总分。
- **Windows 题库管理**：导入 ZIP、TSV、CSV 题库，编辑题目，停用或恢复题目。
- **纸面练习与导出**：导出 Markdown 试卷、答题卡、解析和错题集，在 Windows 上打印 PDF。
- **Windows 答题卡阅卷**：从 PNG/JPG/JPEG 图片识别选择题涂卡结果，经人工确认后才保存作答记录。
- **本地存储，可选同步**：使用 SQLite 保存本地数据，通过自己的 Supabase 项目进行账号登录和增量同步。

仓库附带 **15 题测试包**，不包含完整的正式考试题库。

## 双端功能

| 功能 | Windows | Android |
| --- | --- | --- |
| 离线练习与试卷作答 | 支持 | 支持 |
| 简体中文 / 英文界面 | 支持 | 支持 |
| 可选云同步 | 支持 | 支持 |
| 题库导入、更新和编辑 | 支持 | 题库管理只读 |
| Markdown 导出 | 支持 | 支持 |
| PDF 打印 | 支持 | 不支持 |
| 答题卡图片识别 | 支持，须人工确认 | 不支持 |

Windows 阅卷组件为独立的 `paper_omr_bridge` 程序，使用 OpenCV 和 NumPy。输入为图片，不接受 PDF；问答题答案由人工录入。

## 从源码开始使用

以下命令均在本仓库根目录执行，假定 Flutter 已加入 `PATH`。

### 环境要求

- Flutter **3.47.1 stable**，Dart **3.13.1**。应用版本与 SDK 约束见 [pubspec.yaml](pubspec.yaml)。
- Windows：安装 Visual Studio 的 **使用 C++ 的桌面开发**工作负载及 Windows SDK。
- Android：JDK 17、Android SDK，并接受 Android SDK licenses。
- 含阅卷功能的完整 Windows 发行包：另需 Python 3.14。

### 运行

```powershell
flutter pub get
flutter run -d windows
```

Android 使用 `flutter devices` 查看设备，再执行 `flutter run -d <设备ID>`。

首次启动会自动导入测试题库。可直接离线练习，需要双端同步时再配置后端。普通 Flutter 运行不会打包 Windows 阅卷组件。

## 构建发行包

### Windows：包含答题卡阅卷

将示例中的可执行文件路径替换为本机路径：

```powershell
powershell -ExecutionPolicy Bypass -File tool/build_windows_release.ps1 -Flutter C:/flutter/bin/flutter.bat -Python C:/Python314/python.exe
```

脚本会执行清理构建、静态分析和测试，构建 Python 阅卷程序、收集许可材料，并在 `dist/` 下生成完整目录和 ZIP。安装锁定的 Python 依赖需要网络。

**分发完整目录或 ZIP，不要只复制应用 EXE。** 公开发布时使用完整构建，不复用旧包，也不跳过构建阶段。

只编译 Flutter 应用可执行 `flutter build windows --release`，但该命令不打包答题卡阅卷组件。

### Android

```powershell
flutter build apk --release
```

APK 位于 `build/app/outputs/flutter-apk/`。当前 release 配置仍使用 **debug 签名**，用于个人测试；公开分发前应配置自己的正式签名。

中文 `.bat` 启动器和 Android PowerShell 发布脚本包含维护者本机的工具链路径约定。其他机器请使用上述命令，或在脚本支持时显式传入工具链路径。

## 部署可选同步后端

后端源码位于 [supabase/migrations](supabase/migrations)，包含同步表、按用户隔离的行级安全策略和 `sync_exchange` RPC。本项目不提供公共共享云服务。

1. 创建一个新的 Supabase 项目。
2. 使用 Python 3 生成初始化 SQL：

   ```powershell
   python supabase/build_bootstrap.py supabase/bootstrap.local.sql
   ```

3. 检查生成文件，在**新项目的 SQL Editor** 中运行完整 SQL。生成器按顺序合并三份迁移，输出文件已存在时会拒绝覆盖。
4. 运行 [supabase/verify.sql](supabase/verify.sql)，按注释核对预期结果。
5. 启用邮箱密码登录，在 Supabase 管理后台创建已确认邮箱的账号。应用提供登录页，没有注册页。
6. 在应用的“同步与备份”中填写项目 URL 和 **Publishable Key**。两端登录同一账号，题库由 Windows 发布。

客户端只使用公开密钥，不得把 Secret Key、`service_role` 密钥或数据库密码填入客户端密钥栏。

完整步骤、升级说明、常见问题与双账号隔离检查见[部署指南](supabase/README.md)。初始化 SQL 适用于新项目，不要在已有数据库中盲目重复执行。

## 题库与数据

测试包位于 [assets/test-bank](assets/test-bank)。准备自己的内容时，请参照[题库生成要求](docs/题库生成要求.md)。ZIP 支持媒体与更丰富的元数据；TSV/CSV 用于扁平文本题库。

Windows 默认数据目录为 `%APPDATA%/PersonalExamApp/`，Android 使用应用私有目录。卸载或更换设备前应备份或完成同步。数据库和备份可能包含登录会话，不应附在公开 Issue 中。

导入的题目、解析和图片保留各自的权利归属与许可条件。

## 开发与验证

```powershell
flutter analyze
flutter test
```

PDF 集成测试需要 Edge 与 Poppler（`pdfinfo`、`pdftoppm`），缺少工具时可能跳过。阅卷自动化测试使用合成图片，不能替代真实打印答题卡、Android 真机或新部署云端的验收。

## 文档

详细文档目前以中文为主。

| 文档 | 内容 |
| --- | --- |
| [架构说明](docs/architecture.md) | 应用分层、数据契约、评分与同步 |
| [后端部署](supabase/README.md) | 创建自己的 Supabase 项目 |
| [题库生成要求](docs/题库生成要求.md) | 制作可导入的题库 |
| [国际化说明](docs/i18n.md) | 中英文文案及导出标签 |
| [验证记录](docs/validation.md) | 已完成检查与验证边界 |
| [阅卷组件来源核查](docs/omr-decoupling.md) | 组件来源与实现历史 |
| [许可说明](docs/licensing.md) | 协议选择及分发范围 |

## 开源协议

项目自有代码与文档采用 [MIT License](LICENSE)。第三方依赖保留各自许可，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

本项目的许可不授予使用者对他人导入题库、图片或个人数据的权利。
