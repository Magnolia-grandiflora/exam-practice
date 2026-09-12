# 部署自己的同步后端

同步端代码已包含在 `migrations/`：三张 PostgreSQL 表、按账号隔离的 RLS 策略和 `public.sync_exchange` RPC。无需另写服务器或部署 Edge Function；登录和 REST API 由 Supabase 提供。本仓库不提供共享云服务，也不包含维护者的账号、用户数据或服务器备份。

本指南面向**新建 Supabase 托管项目**。普通 PostgreSQL 不够，还需要 Supabase Auth 和 Data API；自行托管整套 Supabase 不在本指南验收范围内。

## 1. 创建项目

1. 在自己的 Supabase Dashboard 创建空项目，等待数据库就绪。
2. 在项目连接/API 设置中取得 Project URL（如 `https://YOUR_PROJECT_REF.supabase.co`）和 Publishable Key（`sb_publishable_...`）。
3. 保持 Data API 启用并暴露 `public` schema。应用不用 Storage bucket 或 Realtime，题库图片以媒体分块记录存入数据库。

Publishable Key 可以进入公开客户端；数据库密码、Secret Key、service_role Key 不得填入应用或提交仓库。参见 [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys)。

## 2. 初始化数据库

在仓库根目录执行（Python 3，纯标准库）：

```powershell
python supabase/build_bootstrap.py supabase/bootstrap.local.sql
```

脚本按文件名顺序合并迁移，用一个 BEGIN / COMMIT 事务包裹。输出已存在时拒绝覆盖，再次生成请使用新文件名。生成文件是派生产物，权威源码仍是：

| 顺序 | 文件 | 内容 |
| --- | --- | --- |
| 1 | `20260819204155_create_exam_sync_backend.sql` | 同步表、RLS、权限、v1 RPC |
| 2 | `20260819204455_add_changes_entity_fk_index.sql` | 外键查询索引 |
| 3 | `20260820111733_question_catalog_sync.sql` | 题库、题目、媒体分块和 v2 RPC |

打开新项目的 **SQL Editor → New query**，粘贴生成文件的完整内容并运行。见 [官方数据库指南](https://supabase.com/docs/guides/database/tables)。三份必须全部执行，当前客户端使用协议 v2。

不用 Python 时，可在一条查询中写入 `BEGIN;`，依次粘贴三份 SQL，最后写入 `COMMIT;` 并运行。

此方式只用于新项目。出现 `relation already exists` 时不要删表重试，应先检查已有数据和已部署版本。SQL Editor 手动执行不会自动登记 Supabase CLI 迁移历史；后续转用 CLI 时须核对并登记已有版本，不能重放全部迁移。升级旧项目应先备份，仅执行尚未部署的迁移。

## 3. 检查结构与创建账号

运行 [verify.sql](verify.sql)，按注释核对：3 张表启用并强制 RLS、9 条按 auth.uid() 限制的策略、RPC 为 security invoker、普通登录用户可执行而匿名用户不可执行，以及六种 v2 实体类型。结构检查不等于实际同步验收。

在 **Authentication** 中启用 Email/password 登录，在 **Users → Add user / Create new user** 创建邮箱密码账号。当前应用只有登录功能，没有注册页面。未确认邮箱的账号应先完成确认，或在管理端创建已确认的测试账号。无需 OAuth。参见 [Password-based Auth](https://supabase.com/docs/guides/auth/passwords)。

## 4. 连接应用

Windows 的“同步与备份”页保存 Project URL 和 Publishable Key，再用普通邮箱账号登录。Android 使用同一项目和账号。URL 不要追加 /rest/v1 或 /auth/v1。

也可以编译默认配置（设置页已保存值优先）：

```powershell
flutter build windows --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

这条命令只编译 Flutter 程序；含 OMR 的完整发行包见仓库 [README](../README.md)。不配置云端也可离线使用。

## 5. 新项目验收

使用隔离安装/数据目录和内置 15 题测试包，不使用个人正式数据。

1. Windows 登录测试账号 A，同步内置题库，作答一道题并同步，待上传队列应清空。
2. 第二个隔离客户端登录 A 并同步，应收到题库和作答。Android 题库管理只读，题库由 Windows 发布。
3. 第二端断网作答另一题，联网同步，再回 Windows 同步，应看到新增记录。重启两端再次同步，记录不重复，队列收敛。
4. 用另一个干净数据目录登录账号 B，不应收到 A 的作答或试卷。内置测试题库随应用附带，不能用“看到同名测试题库”判断泄漏。
5. 冲突与幂等性还需协议验收：同一 event_id 同内容重放不新增事件；不同内容不得覆盖原事件，应记录 exam_sync_conflicts。本地对应测试在 test/sync_service_test.dart 和 test/database_test.dart，本地通过不能替代部署后 RPC 验收。

SQL Editor 管理员能看到所有账号数据，不能用管理员查询替代普通用户的 RLS 验证。

## 常见问题与维护

| 现象 | 检查 |
| --- | --- |
| 找不到 sync_exchange / PGRST202 | 三份迁移是否成功、public 是否暴露、API schema cache 是否刷新 |
| unsupported schema version / entity type | 是否漏掉第三份迁移 |
| 登录失败 / Email not confirmed | URL、账号密码、邮箱确认状态和 Email 登录开关 |
| 401/403 / permission denied | key 是否属于该项目、是否已登录、函数授权和 RLS 检查结果 |
| Android 缺题库 | Windows 是否先上传、两端是否同项目同账号 |

客户端调用 `POST /rest/v1/rpc/sync_exchange`，参数为 p_device_id、p_cursor、p_items、p_schema_version=2；apikey 使用公开 key，Authorization Bearer 使用用户 access token。返回 accepted_outbox_ids、changes、next_cursor。单次最多接收 100 条、拉取 500 条，客户端连续拉取直至收敛。

云端清理最新 10 份以外且已由 Windows 确认归档的试卷，并非绝对只存 10 份。备份应覆盖云数据库和本地数据；删除 Auth 用户会级联删除其同步数据。

本次提供的 SQL 已做源码核对和生成检查，未在新的 Supabase 项目实际执行，也未宣称通过真实云同步和跨账号验收。
