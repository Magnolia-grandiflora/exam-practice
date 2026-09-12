# 题序 / Exam Practice 0.1.0

首次公开版本的发布说明草稿。

题序面向拥有大量历年真题和教辅题目的考试，将个人题库整理为持续练习、错题回顾和组卷检验的过程。支持 Windows 与 Android，离线即可使用，可自行部署 Supabase 同步后端。

## 功能

- Windows 导入 ZIP、TSV、CSV 题库；Android 题库管理只读。
- 未见题优先、错题回顾、作答记录和统计。
- 自定义题型数量和试卷评分，支持问答题文本保存；问答题不自动判分。
- Markdown 导出、Windows PDF 打印与答题卡图片阅卷；识别结果须人工确认。
- 中英文界面，新的“题序 / Exam Practice”名称及统一应用图标。

## 发布文件

- `ExamPractice-Windows-x64-0.1.0.zip`：解压完整目录后运行 `personal_exam_app.exe`，不要单独移动 EXE。
- `ExamPractice-Android-0.1.0-test-signed.apk`：现有 debug 证书签名，仅供个人测试。

源码附 MIT License、第三方声明、15 题测试包及同步后端部署材料。Windows 包含阅卷组件和依赖许可文本。

## 安装与验证边界

本地发布构建已完成：静态分析通过，108 项 Flutter 测试通过，Windows 完整发布包与 Android release APK 均生成成功。已从 Windows EXE 与 APK 提取并检查新图标，核对成品版本为 0.1.0+1、名称为“题序 / Exam Practice”。Windows 包含 49 份 Python/依赖许可文本。两个成品的 SHA-256 列于 `dist/SHA256SUMS-0.1.0.txt`。

此版本使用 `0.1.0+1`，作为首次公开版本。Android versionCode 为 1，不能直接覆盖此前 versionCode 为 20 等更高版本的测试安装；不要为降级而直接卸载仍有未备份数据的应用。

未进行本次真机安装、真实纸张识别或新云项目同步验收。APK 尚未改用正式发布签名。应用不附完整正式考试题库，原始 Word、PDF、扫描教辅需转换为规定题库格式后再导入。
