# Exam Practice · 题序

<img src="docs/assets/icon.png" alt="Exam Practice icon" width="128" height="128">

**Turn past papers and study-guide questions into a structured practice routine.**

[![阅读中文版](docs/assets/readme-zh.svg)](README.zh-CN.md)

Exam Practice is a question-practice tool for exam preparation built around large collections of past papers, practice workbooks, and study-guide exercises. It is intended for exams where a defined syllabus and recurring question formats make systematic practice useful, including qualification, certification, and entrance exams.

The English name describes its purpose directly: practicing for exams. Its Chinese name, **题序**, combines **questions (题)** and **sequence (序)**. The central idea is to give a large question collection a usable order: cover unseen questions, revisit mistakes, and test yourself with custom papers. Keep answer records and explanations alongside that process so each round of practice can inform the next.

The app runs on Windows and Android, with an English or Simplified Chinese interface. It uses Flutter and SQLite and works offline.

Study without an account or internet connection. If you want to share progress between devices, deploy your own optional Supabase sync backend using the SQL included in this repository.

## From study materials to practice

1. **Prepare your question bank.** Organize questions from past papers and study materials you are entitled to use, keeping answers, explanations, years, chapters, and sources where available. Convert them to the supported ZIP, TSV, or CSV format and import on Windows.
2. **Build coverage.** Work through unseen questions, using filters to focus on a year, chapter, or topic. See which questions you have already answered instead of repeatedly opening the same familiar exercises.
3. **Review mistakes.** Return to incorrect answers and their explanations after covering unseen questions in the practice pool. Use answer history to guide further study of the source material.
4. **Check exam readiness.** Assemble timed papers with the question mix and scoring you need, review the results, and export papers or mistake collections for printed practice.

Raw Word files, PDFs, and scanned textbooks must be converted into the [question-bank format](docs/题库生成要求.md) before import. Automatic extraction of questions from those documents is not built into the app. The repository includes a sample bank; you supply the exam content.

## What you can do

- **Practice with a clear order:** work through unseen questions before returning to mistakes, with answer history, filters, and statistics.
- **Build your own papers:** choose question counts by type, save drafts, track time, and navigate a paper by question number.
- **Customize paper scoring:** set single-choice and multiple-choice points, partial credit, and how incorrect selections are handled. Each paper keeps its scoring policy.
- **Include written-answer questions:** save written responses with the paper; these questions are not automatically graded or included in the total score.
- **Manage question banks on Windows:** import ZIP, TSV, or CSV files; edit questions and disable or restore them.
- **Take your work to paper:** export Markdown papers, answer sheets, explanations, and mistake collections; print PDFs on Windows.
- **Review scanned answer sheets on Windows:** recognize marked choices from PNG/JPG/JPEG images and confirm the results before saving answer records.
- **Keep data local, with optional sync:** use SQLite locally and your own Supabase project for account-based incremental synchronization.

The repository includes a **15-question sample bank**, not a complete exam question bank.

## Platform support

| Capability | Windows | Android |
| --- | --- | --- |
| Offline practice and exam papers | Yes | Yes |
| English / Simplified Chinese interface | Yes | Yes |
| Optional cloud synchronization | Yes | Yes |
| Question-bank import, updates, and editing | Yes | Read-only bank management |
| Markdown export | Yes | Yes |
| PDF printing | Yes | No |
| Image-based answer-sheet recognition | Yes, with manual confirmation | No |

The Windows recognition component uses OpenCV and NumPy in a separate `paper_omr_bridge` executable. It accepts images, not PDF input. Written answers are entered manually.

## Try it from source

Run the following commands from this repository's root. These examples assume Flutter is on your `PATH`.

### Requirements

- Flutter **3.47.1 stable**, with Dart **3.13.1**. See [pubspec.yaml](pubspec.yaml) for the application version and SDK constraint.
- For Windows: Visual Studio with the **Desktop development with C++** workload and the Windows SDK.
- For Android: JDK 17, Android SDK, and accepted Android SDK licenses.
- For the complete Windows package with answer-sheet recognition: Python 3.14.

### Run

```powershell
flutter pub get
flutter run -d windows
```

For Android, run `flutter devices` and then `flutter run -d <device-id>`.

The built-in sample bank is imported on first launch. Start with offline practice; configure synchronization only if you need it. A plain Flutter run does not package the Windows recognition executable.

## Build packages

### Windows, including answer-sheet recognition

Replace the example executable paths with your own:

```powershell
powershell -ExecutionPolicy Bypass -File tool/build_windows_release.ps1 -Flutter C:/flutter/bin/flutter.bat -Python C:/Python314/python.exe
```

The script runs a clean build, analysis and tests, builds the Python recognition executable, collects license materials, and creates a directory and ZIP under `dist/`. Installing the locked Python dependencies requires network access.

**Distribute the whole directory or ZIP, not just the application EXE.** Use a complete build for a public release rather than reusing an older package or skipping build stages.

To compile only the Flutter application, run `flutter build windows --release`. That command does not package answer-sheet recognition.

### Android

```powershell
flutter build apk --release
```

The APK is generated under `build/app/outputs/flutter-apk/`. The current release configuration uses a **debug signing key** for personal testing; configure your own release signing before public distribution.

The Chinese `.bat` launchers and Android PowerShell release script contain maintainer-specific toolchain paths. For another machine, use the commands above or explicitly supply your toolchain paths where supported.

## Deploy optional synchronization

The backend is included in [supabase/migrations](supabase/migrations). It consists of database tables, per-user row-level security policies, and the `sync_exchange` RPC. No shared hosted service is provided.

1. Create a new Supabase project.
2. Generate a single initialization SQL file with Python 3:

   ```powershell
   python supabase/build_bootstrap.py supabase/bootstrap.local.sql
   ```

3. Review and run the generated SQL in the **new project's SQL Editor**. The generator combines all three migrations in order and refuses to overwrite an existing output file.
4. Run [supabase/verify.sql](supabase/verify.sql) and compare the results with its expected-output comments.
5. Enable email/password authentication and create a confirmed user account in the Supabase dashboard. The app has a sign-in screen, not a registration screen.
6. Enter the project URL and **Publishable Key** in the app's sync settings. Sign in to the same account on both devices; Windows publishes the question banks.

Use only the public client key in the app. Never enter a Secret Key, `service_role` key, or database password as the client key.

The complete [deployment guide](supabase/README.md) is currently in Chinese and includes upgrade notes, troubleshooting, and a two-account isolation check. Initialization SQL is for a new project; do not replay it blindly against an existing database.

## Question banks and data

The sample bank is in [assets/test-bank](assets/test-bank). For your own content, see the [question-bank format specification](docs/题库生成要求.md) (Chinese). ZIP packages support media and richer metadata; TSV/CSV provide a flat text format.

Windows stores application data under `%APPDATA%/PersonalExamApp/` by default. Android uses private app storage. Back up or synchronize before uninstalling or changing devices. Databases and backups may contain session tokens and should not be attached to public issues.

Imported questions, explanations, and images retain their own ownership and licensing.

## Development and verification

```powershell
flutter analyze
flutter test
```

PDF integration tests require Edge and Poppler (`pdfinfo`, `pdftoppm`); missing tools may cause skips. Recognition tests use synthetic images. Automated checks do not replace tests with printed answer sheets, real Android devices, or a newly deployed cloud backend.

## Documentation

Most detailed documentation is currently in Chinese.

| Document | Contents |
| --- | --- |
| [Architecture](docs/architecture.md) | Application layers, data contracts, scoring, and synchronization |
| [Backend deployment](supabase/README.md) | Set up your own Supabase project |
| [Question-bank specification](docs/题库生成要求.md) | Prepare importable question banks |
| [Localization](docs/i18n.md) | English / Chinese strings and export labels |
| [Validation records](docs/validation.md) | Recorded checks and verification limits |
| [Recognition source review](docs/omr-decoupling.md) | Component provenance and implementation history |
| [Licensing](docs/licensing.md) | License choice and distribution scope |

## License

Project-owned code and documentation are available under the [MIT License](LICENSE). Third-party dependencies retain their own licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The project license does not grant rights to users' imported question banks, images, or personal data.
