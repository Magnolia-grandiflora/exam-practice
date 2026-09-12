# 架构与数据契约

## 边界

```text
Flutter UI
  -> AppController / use cases
    -> 纯 Dart 判分与学习策略
    -> AppDatabase (SQLite)
    -> BankImporter / BackupService / MarkdownExporter / SyncService
```

业务层不依赖 Supabase SDK。`SyncService` 面向 `CloudSyncGateway`；当前 Windows 构建
通过 HTTPS 调用 Supabase Auth 和 PostgREST RPC，因此云端变化不会改写判分、历史或
SQLite 核心层，也不引入 Windows 原生插件。

## SQLite

核心表：

- `question_banks` / `questions`：稳定 UUID、内容版本、题型、A—E、答案、解析、来源和评分规则；
- `question_progress`：读取优化聚合，真实历史以事件为准；
- `answer_events`：不可变事件与载荷哈希；
- `paper_attempts` / `paper_attempt_questions`：草稿、计时、固定事件 ID 和题目快照；
- `sync_outbox` / `sync_conflicts`：增量同步、重试与冲突；
- `deferred_sync_changes`：题目尚未到达时暂存其答题、进度和控制变化；
- `question_control_versions`：收藏、不确定、排除和个人笔记控制操作的独立版本；
- `synced_entity_hashes`：已拉取不可变实体的载荷指纹；
- `synced_media_chunks`：媒体分块元数据、完整文件哈希和本地落盘状态；
- `question_bank_imports` / `local_backups` / `app_settings`。

所有正式作答在一个 `BEGIN IMMEDIATE` 事务内写入事件、聚合状态和 outbox。相同 `event_id` + 相同载荷返回幂等重放；相同 ID + 不同载荷写入冲突并拒绝覆盖。

## 同步协议

`POST /rest/v1/rpc/sync_exchange` 接收 `p_device_id`、当前 `p_cursor` 和最多 100 条
`p_items`，返回已确认的 outbox ID、游标后的变化和 `next_cursor`。客户端把大队列拆成
不超过约 4 MiB 的批次，并连续换页直到收敛。在单一 SQLite 事务中完成上传确认、
远端变化合并、受影响学习状态重算和游标推进；未知或损坏变化会使整批回滚。

- 题库目录：Windows 发布 `question_bank` 与 `question`，按内容版本和实体版本合并；
- 媒体：以 512 KiB 分块发布，逐块校验后按完整文件 SHA-256 原子落盘；
- 答题事件：按 `event_id` 取并集；同 ID 不同载荷只记冲突，不覆盖；
- 试卷快照：按 `attempt_id` 唯一，写入 Windows 永久历史后生成
  `paper_archive_ack`；
- 收藏/不确定/排除：控制版本优先，同版本按 UTC 时间和设备 ID 稳定决胜；
- 个人笔记：检测共同基线后的双方编辑，保留本地正文并把远端正文写入冲突表；
- 依赖延迟：先到达的答题、进度或控制变化进入 `deferred_sync_changes`，对应题目到达后
  自动重放，不因单条依赖缺失阻断其余目录同步；
- 游标：只有整个本地合并事务成功后才更新。

Supabase 中的 `exam_sync_entities`、`exam_sync_changes` 和 `exam_sync_conflicts` 全部启用
RLS，并以 `(select auth.uid()) = user_id` 限制普通账号只能访问自己的数据。
`sync_exchange` 使用 `security invoker`，在单个 PostgreSQL 事务中处理 push/pull。
云端始终保留每位用户最新 10 份完整试卷；更早记录只有收到 Windows 的
`archived_by_windows_at` 后才可裁剪。

## 题库 ZIP

```text
bank-package.zip
  manifest.json
  questions.jsonl
  media/*
```

阻断项包括：JSON/ZIP 解析失败、schema 不支持、题目/媒体哈希不匹配、重复题目 ID、无效题型、空题干、少于两个选项、答案越界、单选多答案和媒体缺失。警告不阻断导入，包括重复 external_id/题干、解析或来源信息为空。

## TSV / CSV 扁平题库

程序同时接受 UTF-8 编码的 `.tsv` 和 `.csv`。TSV 使用 Tab 分隔，CSV 支持双引号、
逗号、双引号转义和单元格内换行。文件开头可用 `# key: value` 声明题库 ID、名称、
科目和版本；未给出 `bank_id` 时，程序按题库名称与科目生成稳定 ID。每道题的稳定 ID
由 `bank_id + 编号` 自动生成，也可通过可选的“题目ID”列显式提供。

扁平格式的必需列为“编号、题型、题干、选项A、选项B、答案”；选项 C—E 及年份、
解析、考点、来源、章节、Tags 等为可选列。扁平格式采用默认评分规则且不携带媒体，
图片题和自定义评分规则继续使用 ZIP。完整生成规范见
[题库生成要求.md](题库生成要求.md)。

内置测试包可由 `tool/generate_test_bank.ps1` 重复生成；固定为 10 单选 + 5 多选，含两张图片、一张 Markdown 表格和一对相似题。

## 计时

整卷时间为打开试卷页面且应用处于前台期间的真实累计时长：离开页面或应用最小化即暂停，重新打开后从已累计时长继续（不按组卷时刻起的墙钟时间重算）。每题时间在活动题切换/周期保存时累计，是交互估计值，不宣称为精确阅读时间。每次选项变化立即保存草稿。

## 试卷组卷与固定评分

试卷组卷模式为 `singleOnly`、`multipleOnly`、`realExam`。前两种模式只取对应题型；
`realExam` 支持自定义各题型数量（`PaperTypeCounts`：单选/多选/问答题绝对题数，
顺序固定为单选在前、多选随后、问答题最后，库存不足按现有数量取题）；不传数量时
沿用历史 14:3 比例（多选题数量为总题数乘 `3 / 17` 后四舍五入，不含问答题）。
练习模式不使用这套试卷组合配置，继续采用题库题目的评分规则。

试卷判分策略（`PaperScoringPolicy`，kind `uniform_exam_v2`）可在设置页自定义：
单选/多选每题分值、多选少选部分分开关与每正确项分值、错项是否整题零分；策略随卷
快照持久化，修改只影响新试卷，旧快照（含 v1）反序列化为历史默认值。空题为 0 分但
不生成作答事件；总分按 `score / maxScore * 100` 换算为百分制。

### 题目排版标记

题干、选项与解析可能携带 `<p>`、`<br>` 等排版标记。设置项
`render_question_markup`（默认开启）决定处理方式：开启时经
`lib/domain/question_text.dart` 的 `renderMarkupText` 转换为换行等纯文本语义
（块级元素边界换行、`<br>` 换行、实体解码、`&nbsp;` 转普通空格），UI 与
Markdown/PDF 导出一致；关闭时 UI 维持历史剥离行为、导出原样保留标记。
题目编辑对话框始终编辑原文。

### 问答题（qa）

- 题型 `qa`：无选项，`answers` 为参考答案原文（可空）。数据库 CHECK 约束经
  迁移 v4 放宽（重建 questions 表）。
- 不判分（`maxScore` 0）、不计入总分、不生成作答事件；作答文本保存在试卷快照
  `selected_json`（单元素数组，原文不归一化）。
- 练习池排除问答题；问答题出现在题库浏览、组卷、空白试卷（题下留作答区）、
  答题卡问答区与导出文档中。

## Windows PC 阅卷与 PDF 打印边界

Windows PC 调用随发布包提供的独立阅卷 sidecar `paper_omr_bridge.exe`（源码位于
`tool/paper_omr_bridge/`，基于 OpenCV + NumPy，不包含 OMRChecker 上游代码，
来源核对见 [omr-decoupling.md](omr-decoupling.md)），图片输入仅接受
PNG/JPG/JPEG。识别结果必须经过人工确认后才写入作答事件；`confidence` 字段
恒为 0.0（未估计），不作为展示依据。答题卡气泡按选择题压缩编号（q1..qM，
行首打印试卷题号），问答题不参与机读、由人工在复核页录入后确认；Dart 侧按压缩
顺序把识别标签映射回试卷题位。Android 未接入、未修改这条 Windows PC OMR 链路。

PDF 由 Windows 上的 Chromium 内核打印并输出页码。试卷文档支持 A4 或 A3 排版
（A3 为纵向双栏，经命名页 `@page a3paper` 实现）；答题卡恒为 A4。选择 A3 且同时
导出答题卡时，试卷文档与答题卡分别输出两个独立 PDF，避免单文档混排页尺寸。
导出内容可自由组合（试卷 / 答题卡 / 答案与解析 / 回顾），仅 PDF 模式同样只打印
所选内容，不再强制捆绑答题卡。题目排版按真实试卷习惯处理：每道题通过
`break-inside: avoid` 尽量整题保持在同一页，因此天然不会出现题目从偶数页跨到奇数页的拆题；
仅当单题高度超过整页内容区时才允许自然分段。不再使用行距压缩或强制移页脚本，全卷行距保持一致。

## 历史与导出

交卷时只为已答题生成固定 `event_id`；未答题按 0 分统计但保持未见。历史试卷读取提交时快照，不随题库更新变化。试卷导出包只生成 UTF-8 Markdown、JSON 清单和二维码/定位点 PNG；Windows 可再将导出包打印为带页码的 PDF，不把 HTML 作为导出物保存。
