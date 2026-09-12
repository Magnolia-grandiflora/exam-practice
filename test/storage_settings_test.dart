import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_exam_app/app_controller.dart';
import 'package:personal_exam_app/data/app_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('存储目录设置保存在独立配置文件并可恢复默认', () {
    final root = Directory.systemTemp.createTempSync('personal-exam-paths-');
    addTearDown(() => root.deleteSync(recursive: true));
    final databaseDirectory = Directory(p.join(root.path, 'custom-db'));
    final backupsDirectory = Directory(p.join(root.path, 'custom-backups'));
    final exportsDirectory = Directory(p.join(root.path, 'custom-exports'));

    final paths = AppPaths.at(root);
    paths.setDatabaseDirectory(databaseDirectory);
    paths.setBackupsDirectory(backupsDirectory);
    paths.setExportsDirectory(exportsDirectory);

    final saved = jsonDecode(paths.settingsFile.readAsStringSync()) as Map;
    expect(
      p.equals(saved['database_directory']! as String, databaseDirectory.path),
      isTrue,
    );
    expect(
      p.equals(AppPaths.loadAt(root).database.path, paths.database.path),
      isTrue,
    );
    expect(
      p.equals(AppPaths.loadAt(root).backups.path, paths.backups.path),
      isTrue,
    );
    expect(
      p.equals(AppPaths.loadAt(root).exports.path, paths.exports.path),
      isTrue,
    );

    paths.setDatabaseDirectory(null);
    paths.setBackupsDirectory(null);
    paths.setExportsDirectory(null);
    expect(paths.usesDefaultDatabase, isTrue);
    expect(paths.usesDefaultBackups, isTrue);
    expect(paths.usesDefaultExports, isTrue);
  });

  test('迁移数据库后立即切换且保留测试题库和会话设置', () async {
    final root = Directory.systemTemp.createTempSync('personal-exam-move-');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final controller = await AppController.createForTesting(root);
    addTearDown(controller.dispose);
    expect(controller.error, isNull);
    controller.database.setSetting(
      'sync_refresh_token',
      'refresh-test',
      syncScope: 'local',
    );
    expect(controller.database.listBanks().single.questionCount, 15);
    final original = File(controller.paths.database.path);
    final destination = Directory(p.join(root.path, 'moved'));

    await controller.moveDatabaseTo(destination);

    expect(
      p.equals(controller.paths.database.parent.path, destination.path),
      isTrue,
    );
    expect(controller.paths.database.existsSync(), isTrue);
    expect(original.existsSync(), isTrue);
    expect(controller.database.listBanks().single.questionCount, 15);
    expect(controller.stats.total, 15);
    expect(controller.hasSavedSyncSession, isTrue);
    expect(
      controller.database.getSetting<String>('sync_refresh_token'),
      'refresh-test',
    );
  });
}
