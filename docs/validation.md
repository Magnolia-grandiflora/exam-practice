# 验证记录

## 2026-09-12 回归：问答题支持 + 组卷/判分自定义 + 导出解耦与 A3

### 已验证

- `flutter analyze`：无问题。
- `flutter test`：**108/108 通过**（97 项既有回归 + 11 项新功能测试，
  见 `test/qa_support_test.dart`）。
- 新功能自动化覆盖：
  - 问答题 TSV 导入（参考答案原文保留、空白参考答案不阻断、带选项阻断
    `import.blocked.qaWithOptions`）；
  - 考试模式自定义题型数量组卷（顺序 单选→多选→问答、库存不足取现有、
    不传数量保持历史 14:3）；
  - 判分策略 v2 自定义（分值/部分分/错项零分开关）与 v1 旧快照兼容；
  - 含问答题试卷：草稿原文持久化、交卷不产生问答题事件、总分只含选择题、
    答题卡气泡压缩编号（q1..qM）与模板只覆盖选择题、问答区渲染；
    纯问答题导出答题卡被拒（`export.sheetNeedsChoice`）；
  - 阅卷复核：识别结果按压缩序映射选择题位、问答题人工录入随确认写入快照且
    不产生事件。
- 数据库迁移 v4：旧库 questions 表 CHECK 约束放宽（按 SQLite 官方 12 步流程
  重建表），内存库与迁移路径均有测试覆盖。

### 0.1.0 GitHub 首发版发行包（2026-09-12）

版本号自本版起重置为 0.1.0+1（pubspec.yaml 唯一来源），作为 GitHub 公开发布的第一版；
此前的 0.6.x—0.8.0 为私有开发期版本号，不再延续。

- 发行包命名自 0.1.0 起改为 `ExamPractice-*`（维护者更改，脚本同步）。
- Android：`dist/ExamPractice-Android-0.1.0-test-signed.apk`（64,255,486 字节），SHA-256
  `602d363e8d960698d8dea2a4affc637e4aa1f3082bc7c5c9ded2fdef832c1c79`；
  aapt 核对 `versionCode=1 / versionName=0.1.0`、minSdk 24、targetSdk 36；
  仍为 debug 测试签名，不能作为正式分发签名。已在装有旧 0.8.0（versionCode 20）
  包的设备上安装时需先卸载（版本号重置导致无法覆盖安装）。
- Windows：`dist/ExamPractice-Windows-x64-0.1.0.zip`，SHA-256
  `bb0d1ecf9a69a48fd9a6fb524c2950b250b6a09d6b966b133dbc19f625880b5e`；
  完整流水线（clean → analyze → 119 项测试 → 构建 → sidecar 冻结自检
  `synthetic geometry checks passed`）在含排版标记渲染、判卷视图、计时累计与
  A3 横向排版的最终代码上通过；包内 0 处 OMRChecker 残留。
- Android：`dist/ExamPractice-Android-0.1.0-test-signed.apk`，SHA-256
  `6a2b0831d71b30195d86956ba1d54aaa80c43669aacb8d4caf0dc28634b45ff3`
  （含排版标记渲染与计时累计修正）。
- A3 试卷排版为横向（landscape）双栏；答题卡恒为 A4 纵向。

### 2026-09-12 体验修正（追加）

- 阅卷确认后不再直接退出复核页：确认写入成功后页面原地转为判卷情况视图
  （得分/百分制/未答/用时汇总 + 逐题核对卡片），由用户点击"返回试卷"返回；
  返回后试卷页保持交卷状态与得分条。测试 `test/omr_return_flow_test.dart`
  以生产相同的后台 isolate 交卷路径验证全链路。
- 试卷计时语义变更：整卷时间为打开页面且应用前台期间的真实累计时长，
  离页/最小化暂停，重开续计；不再按组卷时刻起的墙钟时间重算
  （此前未打开的试卷也会累计墙钟时间）。已在 `docs/architecture.md` 同步。

### 2026-09-12 追加：题目排版标记渲染开关

- 新增设置项 `render_question_markup`（默认开启）：开启时题干/选项/解析中的
  `<p>`、`<br>` 等标记在 UI 与导出中转换为换行等语义；关闭时 UI 维持历史剥离、
  导出原样保留。转换实现 `lib/domain/question_text.dart`；数学不等号
  （`a < b`）不会被误当标记。
- 测试：`test/question_markup_test.dart` 10 项（渲染器、设置持久化、导出跟随）；
  全量 119/119 通过，analyze 无问题。

### 尚未验收（延续 2026-09-11 清单）

- 真实 A4/A3 纸张打印 + 真实拍照的 PC 阅卷逐题人工对照（含问答题手写作答区
  的实际打印布局）；合成图测试不能替代。
- 双端真机人工走查（问答题作答、语言切换、判分设置、A3 导出）。
- 真实云同步：问答题作答文本随试卷快照同步的实测（协议与 payload 结构不变，
  自动化测试覆盖序列化/反序列化）。
- GitHub 托管 CI 首次运行；Android 正式签名。

以下为 2026-09-11 回归记录。

---

## 2026-09-11 回归：依赖现代化 + OMR 解耦 + i18n

工具链：Flutter 3.47.1 stable（`.tooling/flutter-3.47.1`）/ Dart 3.13.1；
Android AGP 9.4.0 + Gradle 9.7.1 + Kotlin 2.4.20 + JDK 17.0.20+8；
Python 3.14.7（独立 venv `.tooling/py3147-sidecar-venv`）+ numpy 2.5.3 +
opencv-python-headless 5.0.0.93 + PyInstaller 6.22.2；
Visual Studio Build Tools 2022 17.14.21 / Win SDK 10.0.26100.0。

### 已验证

- `flutter analyze`（3.47.1）：无问题（含 i18n 全量迁移与服务层错误码化后）。
- `flutter test`：**97/97 通过**（原 90 项 + 新增 i18n 5 项 + 导出标签 2 项），
  含 PDF 集成测试（poppler 在 PATH，`.tooling/poppler`）。
- 语言切换：跟随系统/zh/en 三态、重启持久化（`locale_tag` 设置项）、仅本地不入同步
  outbox，见 `test/i18n_test.dart`；en 长文案溢出检查中发现并修复统计卡 Row 溢出。
- 导出标签：zh 与历史默认值逐字一致（中文导出产物不变），en 模板令牌完整，
  见 `test/export_labels_test.dart`。
- Python sidecar：`unittest` 9/9（含 6 项真实 OpenCV/NumPy 合成整卡识别）、
  `pip check` 通过；发布脚本内 PyInstaller 冻结（Python 3.14.7 venv，锁定版本安装）
  后冻结自检 `synthetic geometry checks passed`。
- Windows 完整发行包：`dist/个人刷题-Windows-x64-0.8.0.zip`，85,970,698 字节，
  SHA-256 `a8df3c7dd683938ccb28c9f0b61d21bca707367e81072a220ee6d03950846b26`。
  包内容核验：0 处 OMRChecker/omrchecker 匹配（解耦彻底，无增量混入）；
  含 `paper_omr_bridge.exe`、`sqlite3.dll`、`NativeAssetsManifest.json` 映射校验
  （发布脚本强制）、`THIRD_PARTY_NOTICES.md`、桥接源码与两个锁文件。
- Android debug APK：`flutter build apk --debug` 成功（AGP 9.4.0 / Gradle 9.7.1 /
  Kotlin 2.4.20 组合，Flutter warn 阈值之上实测可用）。
- gen-l10n：`pub get` 自动再生成验证（删除 `lib/l10n/generated/` 后恢复），
  生成物已 gitignore，全新检出可直接 analyze。
- CI 工作流版本核对（checkout@v6 / setup-python@v6 / setup-java@v6.0.1 /
  flutter-action@v2，2026-09-11 官方 releases 页）。

### 尚未验收（与 2026-09-07 清单合并）

- GitHub 托管 CI 首次实际运行（仓库未推送远端）。
- Android release APK 真机安装验证（本次仅完成构建）；release 仍为 debug 签名。
- 真实 A4 纸张拍照 / 扫描件的 PC 阅卷逐题人工对照；合成图结果不能替代。
- 真实云同步闭环、题库同步 v2 生产迁移；本次未触碰正式云端数据。
- 在未安装系统 Python 的干净 Windows 环境验证发行包 sidecar。
- Windows/Android 双端双语（zh/en）人工界面走查：自动化测试覆盖关键流程断言，
  但未做逐页人工视觉检查。

以下为 2026-09-07 的历史验证记录（工具链版本与部分结论已过时，以本节为准）。

---

验证日期：2026-09-07。

## 工具链

- Flutter 3.44.7 stable，framework `84fc5cbb22`；
- Dart 3.12.2；
- Visual Studio Build Tools 2022 17.14.21；
- Windows SDK 10.0.26100.0；
- Windows 11 25H2。

## 已验证

- Dart 静态分析：通过，无 error/warning；
- Dart 单元、服务级与移动端 Widget 测试：38/38 通过；
- 题库扁平格式：UTF-8 TSV 中文表头可预览并实际写入 SQLite，稳定题目 ID 可重复
  生成；CSV 的逗号、双引号转义和引用字段内换行已通过测试；未知扩展名会拒绝；
- 题库包：15 题，10 单选/5 多选、2 媒体文件，阻断校验为 0；损坏 ZIP 会拒绝；
- 判分：答案标准化、单选多选无效、漏选/错选、可配置部分分；
- 试卷固定判分：单选 1 分、多选 2 分，错项整题 0 分，少选且无错选时每个正确选项
  0.5 分，百分制换算；三种组卷模式 `singleOnly` / `multipleOnly` / `realExam` 中，
  `realExam` 按单选在前、多选在后固定为 14:3；
- SQLite：相同事件幂等、不同载荷冲突、未答题不生成事件、重复交卷不重复、历史快照不随题库更新；
- 同步模拟：一次交换 push/pull、远端事件并集、游标原子提交、失败整批回滚、
  同 ID 冲突不覆盖、个人笔记双方编辑保留冲突、远端试卷写入后归档确认；题库、15 题、
  媒体和作答可从 Windows 空库同步到 Android 空库；先到达的作答会延迟并在题目到达后
  自动重放；205 题目录可分三批上传并清空 outbox；
- 认证模拟：Supabase 邮箱密码登录、Publishable Key 请求头、密码不持久化边界、
  Access/Refresh Token 解析和刷新令牌轮换；
- 筛选与统计：年份、章节、标签和题型组合筛选，标签统计；
- 云端部署：维护者的隔离验证环境已应用两条版本化迁移（公开记录省略个人项目标识）；
  三张同步表 RLS 已开启且强制执行，RPC 为 `security invoker`，匿名角色无执行权，
  数据库对象未发现 Security Advisor 告警；项目级 Auth Advisor 仅提示“泄露密码保护”
  尚未开启，此项需要在 Supabase Auth 设置中按项目策略决定是否启用；
- 题库同步 v2：生产迁移已生成并在实际 PostgreSQL 17 上以 `BEGIN` / `ROLLBACK` 完成
  语法与依赖预检；尚未持久应用，因此本节不把生产题库同步列为已完成；
- 真实云端闭环：普通账号密码登录返回 200，随后 `sync_exchange` 返回 200；云端落库
  19 个实体/19 条变更、0 冲突。修复版再次启动后使用保存的会话自动对账，
  本地待上传由 2 条归档确认收敛为 0，`last_sync_error` 为空；
- 云端裁剪规则：RPC 只裁剪最新 10 份之外且已有 Windows 归档确认的试卷快照；
- Windows debug 构建：通过；
- Windows release 构建：通过；
- Android 0.6.0 release 构建：通过；包名 `com.personalexam.app`，版本 `0.6.0 (10)`，
  `minSdk 24`、`targetSdk 36`、`compileSdk 36`；
- Android APK：`个人刷题-Android-0.6.0-test-signed.apk`，60,573,534 字节，SHA-256
  `4AC156CB8FEF67EC0D3B7C8FF2116256FFFE0C3F2B2F4AC9E6ED14C29304B5F9`；APK v2 签名和
  清单解析通过，当前签名证书为 Android Debug，不能作为正式发布签名；
- Android 真机：OPPO PKJ110、Android 16 / ColorOS 16，ADB 安装成功；冷启动后
  `MainActivity` 为前台 Activity，进程保持存活，筛选日志中未发现 AndroidRuntime、
  Flutter、SQLite 或插件相关致命异常；切到桌面再恢复后 PID 保持不变，前台 Activity
  恢复正常，未发现生命周期相关致命异常；
- Android 首次启动：应用私有目录创建成功，仓库内 15 题测试库自动导入；首页显示
  总题数 15、未见 15、错题 0，练习页的默认策略、筛选、模式卡片和底部导航已完成真机视觉检查；
- Android 0.5.2 窄屏宽度回归：首页统计卡按每行 2 个排列，练习页未见题/错题复习/
  随机练习等模式卡按每行 2 个排列；OPPO PKJ110 覆盖安装后已逐页截图核验；
- 移动端 Widget：窄屏首页/导航、手机横屏仍保持移动布局、页面切换状态保留、Android
  不发送 Windows 专属 `paper_archive_ack` 均通过自动化测试；
- Windows 0.6.0 分发 ZIP：`个人刷题-Windows-x64-0.6.0.zip`，14,409,923 字节，
  SHA-256 `FAB0D2C18BF5DC28DDF808C5CA221DA7BC8EF4FD47C6CCA82A70654DEB3E6EA2`；
- 中文显示：主题明确使用 Windows 已安装的 `Microsoft YaHei UI`；原生 runner
  使用 `/utf-8` 和 Unicode 标题字面量，最终 release 的窗口标题实测为“个人刷题”；
- release 隔离启动：进程正常响应并创建 SQLite 数据库；既有 0.1.0 首次数据库
  `integrity_check=ok` 证据仍保留；
- 登录崩溃回归：旧包在认证/RPC 均成功后，Windows 记录
  `flutter_windows.dll`、`0xc0000005`、偏移 `0x3a9fa`；该特征与 Flutter 3.44
  Windows Release 已知问题一致。Release runner 已禁用 Impeller、选择低功耗 GPU 并将
  UI 线程放回平台线程；修复包完成真实会话自动同步后持续响应，验证窗口内无新增
  Application Error/WER 事件；
- 首次导入：1 个题库、15 题、15 题未见、0 作答事件，导入前备份和 2 张媒体均落盘；
- 服务闭环：题库提交、媒体复制、SQLite 一致性备份、二维码 PNG、试卷/答题卡/解析/回顾 Markdown 均实际生成；
- Windows PC OMR：真实 Windows EXE 已使用固定的 OMRChecker v1.1.0（commit
  `7e6e4b8a895322e1762ed21a6878ab0ad21aaed8`，GPL-3.0）完成合成图识别验证，输入格式
  覆盖 PNG/JPG/JPEG，人工确认后才允许写入作答事件；Android 未接入或修改该 PC 链路；
- PDF：已验证页码输出与整题保持排版——每道题尽量整题同页（`break-inside: avoid`），超高题
  自然分段，全卷行距一致；2026-09-07 移除旧的行距压缩/强制移页脚本后逐页核验通过。分页
  集成测试依赖 poppler（pdfinfo/pdftoppm），未安装时显式跳过；
- 性能夹具：内存 SQLite 导入 5000 题、计算统计并生成 100 题试卷，在测试机上 10 秒阈值内完成；
- 标准窗口关闭请求：被退出确认流程拦截，进程保持响应，没有直接退出。

## 尚未做实机验收

- 11 份真实试卷的云端归档裁剪；SQL 规则和模拟测试已通过，但未向个人正式数据批量
  写入 11 份测试试卷；
- `a4-omr-v4` 指定打印样式下真实 A4 打印；Markdown、二维码和四角标记资源已经生成，但未进行纸张打印；
- OMR 真实验收：真实打印 A4、手机照片或扫描件尚未人工验收；合成图结果不能替代真实纸张验收；
- 题库同步 v2 生产迁移、当前 Windows 525 题上传及 Android 0.6.0 真机下载尚未执行；
  本地协议、依赖合并、媒体校验和多批上传已通过自动化测试，不能据此宣称真实双端
  题库同步闭环已完成；
- Android 多品牌、多系统版本、低内存与长时间后台恢复尚未覆盖；本次仅验证 OPPO PKJ110；
- Android 拍照 OMR 已完成代码与合成图闭环测试，包括二维码校验、四角定位、透视映射、
  气泡填充识别、问题题目筛选、人工修正和确认后事件来源；真实 A4 打印、不同光线、
  不同手机与擦除残留样本仍未完成实拍标定，不能把合成图结果等同于真实纸张验收。
