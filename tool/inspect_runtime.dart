import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/inspect_runtime.dart <database>');
    exitCode = 2;
    return;
  }
  final db = sqlite3.open(args.single, mode: OpenMode.readOnly);
  try {
    Object scalar(String sql) => db.select(sql).first.values.first!;
    Object? setting(String key) {
      final rows = db.select(
        'SELECT value_json FROM app_settings WHERE setting_key=?',
        [key],
      );
      return rows.isEmpty
          ? null
          : jsonDecode(rows.first['value_json'] as String);
    }

    final result = <String, Object>{
      'integrity': scalar('PRAGMA integrity_check'),
      'banks': scalar('SELECT COUNT(*) FROM question_banks'),
      'questions': scalar('SELECT COUNT(*) FROM questions'),
      'single': scalar(
        "SELECT COUNT(*) FROM questions WHERE question_type='single'",
      ),
      'multiple': scalar(
        "SELECT COUNT(*) FROM questions WHERE question_type='multiple'",
      ),
      'unseen': scalar(
        "SELECT COUNT(*) FROM question_progress WHERE state='unseen'",
      ),
      'events': scalar('SELECT COUNT(*) FROM answer_events'),
      'drafts': scalar(
        "SELECT COUNT(*) FROM paper_attempts WHERE status='draft'",
      ),
      'pending_outbox': scalar(
        'SELECT COUNT(*) FROM sync_outbox WHERE completed_at_utc IS NULL',
      ),
      'has_sync_session':
          (setting('sync_access_token') as String? ?? '').isNotEmpty,
      'last_sync_at_utc': setting('last_sync_at_utc') ?? '',
      'last_sync_error': setting('last_sync_error') ?? '',
    };
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  } finally {
    db.close();
  }
}
