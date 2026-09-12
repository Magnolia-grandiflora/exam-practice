# 开源协议与分发

项目自有代码与文档（包含 Supabase SQL 和本项目阅卷组件）采用根目录 [MIT License](../LICENSE)。版权主体使用集合名称 `Personal Exam contributors`，不代替 Git 提交作者身份，也不转移各贡献者版权。

## 为什么选 MIT

| 协议 | 使用和分发要求 | 本项目取舍 |
| --- | --- | --- |
| MIT | 允许使用、修改、商用及再分发；保留版权与许可声明 | 推荐默认方案，方便个人部署和二次开发 |
| Apache-2.0 | 宽松许可，另有明确专利授权及相关终止条件、修改和声明要求 | 需要明确专利条款时可选 |
| GPL-3.0 | 分发受其约束的衍生程序须遵循 GPL 并提供对应源码 | 希望分发的衍生版本保持开源时可选 |

MIT 不要求使用者公开自己的修改，也允许闭源商用。标准条款依据 [OSI MIT](https://opensource.org/license/mit)；其他选项见 [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) 和 [GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)。

## 许可范围

- 第三方库、字体和工具链保留各自许可，根 LICENSE 不给这些作品重新授权。
- 用户导入的题库、题解、图片、个人数据不因使用本软件而成为 MIT 内容。仓库只附带测试包，不包含维护者的正式题库；上传新的题库前应核对其来源授权。
- 当前阅卷组件没有上游 OMR 源码或运行调用。名称清理不能解除真实复制代码的许可义务；历史来源检查与其证据限度保留在 [解耦记录](omr-decoupling.md)。
- PyInstaller 的 bootloader exception 允许按该例外分发组合程序，不等于 PyInstaller 本身改为 MIT。依赖完整文本见 [第三方声明](../THIRD_PARTY_NOTICES.md)。

## 发布材料

源码仓库保留 LICENSE、THIRD_PARTY_NOTICES.md、依赖锁文件和来源记录。Windows 发布脚本会附带根 LICENSE、第三方声明、Python/wheel 原始许可文件与哈希清单，并保留 Flutter 生成的 NOTICES.Z。首次公开发布使用完整 clean 构建，不使用跳过构建的参数，也不复用此前 dist 里的压缩包。

Android APK 保留 Flutter 生成的许可资产；发布 Release 时同时提供 LICENSE 和第三方声明。APK 目前仍为测试签名，正式签名配置是独立待办。

本次没有推送、创建 Release 或变更任何云端。许可证文件已准备好；发布动作与 Git 作者身份仍由维护者决定。
