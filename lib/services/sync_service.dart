import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_database.dart';

class SyncReport {
  const SyncReport({
    required this.uploaded,
    required this.downloaded,
    required this.failed,
    required this.message,
    this.code,
    this.params = const [],
  });

  final int uploaded;
  final int downloaded;
  final int failed;

  /// 中文技术诊断，保持与迁移前逐字一致；测试与日志依赖它。
  final String message;

  /// 用户可见消息的稳定码（如 `sync.timeout`）；UI 层据此映射本地化文案
  /// （见 `lib/ui/error_messages.dart`），无码时回退 message 原文。
  final String? code;

  /// 按位置对应本地化消息占位符的参数；无占位符时为空。
  final List<Object> params;
}

class SyncExchangeResult {
  const SyncExchangeResult({
    required this.acceptedOutboxIds,
    required this.changes,
    required this.nextCursor,
  });

  final Set<String> acceptedOutboxIds;
  final List<Map<String, Object?>> changes;
  final String nextCursor;

  factory SyncExchangeResult.fromJson(Map<String, Object?> json) {
    final rawChanges = json['changes'] as List? ?? const [];
    return SyncExchangeResult(
      acceptedOutboxIds: (json['accepted_outbox_ids'] as List? ?? const [])
          .map((value) => value.toString())
          .toSet(),
      changes: rawChanges
          .map((value) => (value as Map).cast<String, Object?>())
          .toList(growable: false),
      nextCursor: json['next_cursor']?.toString() ?? '',
    );
  }
}

abstract interface class CloudSyncGateway {
  Future<SyncExchangeResult> exchange({
    required String deviceId,
    required String cursor,
    required List<Map<String, Object?>> outboxItems,
  });
}

class SupabaseSyncGateway implements CloudSyncGateway {
  const SupabaseSyncGateway({
    required this.projectUrl,
    required this.publishableKey,
    required this.accessToken,
    this.client,
    this.timeout = const Duration(seconds: 15),
    this.schemaVersion = 2,
  });

  final Uri projectUrl;
  final String publishableKey;
  final String accessToken;
  final http.Client? client;
  final Duration timeout;
  final int schemaVersion;

  @override
  Future<SyncExchangeResult> exchange({
    required String deviceId,
    required String cursor,
    required List<Map<String, Object?>> outboxItems,
  }) async {
    final uri = projectUrl.resolve('/rest/v1/rpc/sync_exchange');
    final headers = {
      'content-type': 'application/json; charset=utf-8',
      'apikey': publishableKey,
      'authorization': 'Bearer $accessToken',
    };
    final requestBody = jsonEncode({
      'p_schema_version': schemaVersion,
      'p_device_id': deviceId,
      'p_cursor': int.tryParse(cursor) ?? 0,
      'p_items': outboxItems,
    });
    final response =
        await (client == null
                ? http.post(uri, headers: headers, body: requestBody)
                : client!.post(uri, headers: headers, body: requestBody))
            .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = (jsonDecode(response.body) as Map).cast<String, Object?>();
    return SyncExchangeResult.fromJson(decoded);
  }
}

class SyncService {
  const SyncService(this.database, {this.mediaRoot});
  final AppDatabase database;
  final String? mediaRoot;

  static const _maxExchangeBytes = 4 * 1024 * 1024;
  static const _maxRounds = 50;

  Future<SyncReport> synchronize(CloudSyncGateway gateway) async {
    var uploaded = 0;
    var downloaded = 0;
    var failed = 0;
    var pending = <Map<String, Object?>>[];
    try {
      for (var round = 0; round < _maxRounds; round++) {
        final candidates = database.pendingOutbox(
          limit: 100,
          includeDeferred: round == 0,
        );
        pending = _boundedBatch(candidates);
        final beforeCursor = database.syncCursor;
        final result = await gateway.exchange(
          deviceId: database.deviceId,
          cursor: beforeCursor,
          outboxItems: pending,
        );
        database.applySyncExchange(
          acceptedOutboxIds: result.acceptedOutboxIds,
          changes: result.changes,
          nextCursor: result.nextCursor,
          mediaRoot: mediaRoot,
        );
        uploaded += result.acceptedOutboxIds.length;
        downloaded += result.changes.length;
        final unaccepted = pending
            .where(
              (item) => !result.acceptedOutboxIds.contains(
                item['outbox_id']?.toString(),
              ),
            )
            .toList();
        if (unaccepted.isNotEmpty) {
          failed += unaccepted.length;
          for (final item in unaccepted) {
            database.markOutboxFailed(
              item['outbox_id']! as String,
              '云端未确认该项目，已保留等待检查',
            );
          }
          break;
        }
        final hasMoreLocal = database.pendingOutbox(limit: 1).isNotEmpty;
        final hasMoreRemote = result.changes.length >= 500;
        if (!hasMoreLocal && !hasMoreRemote) break;
        if (pending.isEmpty &&
            result.changes.isEmpty &&
            result.nextCursor == beforeCursor) {
          failed++;
          break;
        }
      }
      if (failed == 0 &&
          database.pendingOutbox(limit: 1, includeDeferred: true).isNotEmpty) {
        failed = 1;
      }
      final deferred = database.deferredSyncCount;
      final complete = failed == 0 && deferred == 0;
      return SyncReport(
        uploaded: uploaded,
        downloaded: downloaded,
        failed: failed,
        message: complete
            ? '同步完成：上传 $uploaded 项，拉取 $downloaded 项'
            : '已上传 $uploaded 项、拉取 $downloaded 项；'
                  '$failed 项未获确认，$deferred 项等待题库依赖',
        code: complete ? 'sync.done' : 'sync.partial',
        params: complete
            ? [uploaded, downloaded]
            : [uploaded, downloaded, failed, deferred],
      );
    } on TimeoutException {
      for (final item in pending) {
        database.markOutboxFailed(item['outbox_id'] as String, '连接超时');
      }
      return SyncReport(
        uploaded: uploaded,
        downloaded: downloaded,
        failed: pending.length,
        message: '同步超时，本地数据和同步队列均已保留',
        code: 'sync.timeout',
      );
    } catch (error) {
      for (final item in pending) {
        database.markOutboxFailed(
          item['outbox_id'] as String,
          error.toString(),
        );
      }
      return SyncReport(
        uploaded: uploaded,
        downloaded: downloaded,
        failed: pending.length,
        message: '同步失败，本地数据安全：$error',
        code: 'sync.failed',
        params: ['$error'],
      );
    }
  }

  List<Map<String, Object?>> _boundedBatch(
    List<Map<String, Object?>> candidates,
  ) {
    final result = <Map<String, Object?>>[];
    var bytes = 0;
    for (final item in candidates) {
      final itemBytes = utf8.encode(jsonEncode(item)).length;
      if (result.isNotEmpty && bytes + itemBytes > _maxExchangeBytes) break;
      result.add(item);
      bytes += itemBytes;
    }
    return result;
  }
}
