import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AppPaths {
  AppPaths._(
    this.root, {
    this._databaseDirectory,
    this._backupsDirectory,
    this._exportsDirectory,
  });
  static const _storageChannel = MethodChannel('personal_exam/storage');
  static const _settingsFileName = 'storage_paths.json';

  factory AppPaths.at(Directory root) => AppPaths._(root);
  factory AppPaths.loadAt(Directory root) => _load(root);

  final Directory root;
  Directory? _databaseDirectory;
  Directory? _backupsDirectory;
  Directory? _exportsDirectory;

  static Future<AppPaths> resolve() async {
    if (Platform.isAndroid) {
      final filesPath = await _storageChannel.invokeMethod<String>(
        'getFilesDirectory',
      );
      if (filesPath == null || filesPath.isEmpty) {
        throw StateError('Android 应用数据目录不可用');
      }
      return _load(Directory(p.join(filesPath, 'PersonalExamApp')));
    }
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.isEmpty
        ? Directory.current
        : Directory(appData);
    return _load(Directory(p.join(base.path, 'PersonalExamApp')));
  }

  static AppPaths _load(Directory root) {
    final settings = File(p.join(root.path, _settingsFileName));
    if (!settings.existsSync()) return AppPaths._(root);
    try {
      final json = jsonDecode(settings.readAsStringSync());
      if (json is! Map) return AppPaths._(root);
      Directory? directory(String key) {
        final value = json[key]?.toString().trim() ?? '';
        return value.isEmpty ? null : Directory(p.normalize(value));
      }

      return AppPaths._(
        root,
        databaseDirectory: directory('database_directory'),
        backupsDirectory: directory('backups_directory'),
        exportsDirectory: directory('exports_directory'),
      );
    } catch (_) {
      return AppPaths._(root);
    }
  }

  Directory get defaultData => Directory(p.join(root.path, 'data'));
  Directory get defaultBackups => Directory(p.join(root.path, 'backups'));
  Directory get defaultExports => Directory(p.join(root.path, 'exports'));
  Directory get data => _databaseDirectory ?? defaultData;
  Directory get media => Directory(p.join(root.path, 'media'));
  Directory get backups => _backupsDirectory ?? defaultBackups;
  Directory get exports => _exportsDirectory ?? defaultExports;
  Directory get logs => Directory(p.join(root.path, 'logs'));
  File get database => File(p.join(data.path, 'personal_exam.sqlite'));
  File get settingsFile => File(p.join(root.path, _settingsFileName));

  Future<String?> chooseDirectory() =>
      _storageChannel.invokeMethod<String>('chooseDirectory');

  Future<String?> chooseQuestionBankFile() =>
      _storageChannel.invokeMethod<String>('chooseQuestionBankFile');

  bool get usesDefaultDatabase => _databaseDirectory == null;
  bool get usesDefaultBackups => _backupsDirectory == null;
  bool get usesDefaultExports => _exportsDirectory == null;

  void setDatabaseDirectory(Directory? directory) {
    _databaseDirectory = _normalizedOverride(directory, defaultData);
    _persist();
  }

  void setBackupsDirectory(Directory? directory) {
    _backupsDirectory = _normalizedOverride(directory, defaultBackups);
    backups.createSync(recursive: true);
    _persist();
  }

  void setExportsDirectory(Directory? directory) {
    _exportsDirectory = _normalizedOverride(directory, defaultExports);
    exports.createSync(recursive: true);
    _persist();
  }

  Directory? _normalizedOverride(Directory? directory, Directory fallback) {
    if (directory == null) return null;
    final selected = p.normalize(p.absolute(directory.path));
    final defaultPath = p.normalize(p.absolute(fallback.path));
    return p.equals(selected, defaultPath) ? null : Directory(selected);
  }

  void _persist() {
    root.createSync(recursive: true);
    settingsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'database_directory': _databaseDirectory?.path,
        'backups_directory': _backupsDirectory?.path,
        'exports_directory': _exportsDirectory?.path,
      }),
      flush: true,
    );
  }

  void ensureCreated() {
    for (final directory in <Directory>[
      root,
      data,
      media,
      backups,
      exports,
      logs,
    ]) {
      directory.createSync(recursive: true);
    }
  }
}
