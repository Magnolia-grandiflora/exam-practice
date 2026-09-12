import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../data/app_database.dart';
import '../data/app_paths.dart';

class BackupService {
  const BackupService(this.database, this.paths);
  final AppDatabase database;
  final AppPaths paths;

  String create({required String reason}) {
    paths.backups.createSync(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(paths.backups.path, '${stamp}_$reason.sqlite'));
    database.checkpoint();
    database.vacuumInto(file.path);
    final check = sqlite3.open(file.path);
    String result;
    try {
      result = check
          .select('PRAGMA integrity_check')
          .first
          .values
          .first
          .toString();
    } finally {
      check.close();
    }
    if (result != 'ok') {
      file.deleteSync();
      throw StateError('备份完整性检查失败：$result');
    }
    database.recordBackup(file.path, reason, result);
    return file.path;
  }
}
