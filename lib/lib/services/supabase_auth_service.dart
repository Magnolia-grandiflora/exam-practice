import 'dart:convert';

import 'package:http/http.dart' as http;

class SupabaseSession {
  const SupabaseSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAtUtc;
  final String userId;

  factory SupabaseSession.fromJson(Map<String, Object?> json) {
    final user = json['user'] is Map
        ? (json['user'] as Map).cast<String, Object?>()
        : const <String, Object?>{};
    final expiresAtSeconds = (json['expires_at'] as num?)?.toInt();
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    return SupabaseSession(
      accessToken: json['access_token']! as String,
      refreshToken: json['refresh_token']! as String,
      expiresAtUtc: expiresAtSeconds == null
          ? DateTime.now().toUtc().add(Duration(seconds: expiresIn))
          : DateTime.fromMillisecondsSinceEpoch(
              expiresAtSeconds * 1000,
              isUtc: true,
            ),
      userId: user['id']?.toString() ?? json['sub']?.toString() ?? '',
    );
  }
}

class SupabaseAuthService {
  SupabaseAuthService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<SupabaseSession> signIn({
    required Uri projectUrl,
    required String publishableKey,
    required String email,
    required String password,
  }) => _request(
    projectUrl.resolve('/auth/v1/token?grant_type=password'),
    publishableKey,
    {'email': email, 'password': password},
  );

  Future<SupabaseSession> refresh({
    required Uri projectUrl,
    required String publishableKey,
    required String refreshToken,
  }) => _request(
    projectUrl.resolve('/auth/v1/token?grant_type=refresh_token'),
    publishableKey,
    {'refresh_token': refreshToken},
  );

  Future<SupabaseSession> _request(
    Uri uri,
    String publishableKey,
    Map<String, Object?> body,
  ) async {
    final response = await _client
        .post(
          uri,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'apikey': publishableKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    final decoded = _decodeObject(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final reason =
          decoded['error_description'] ??
          decoded['msg'] ??
          decoded['message'] ??
          decoded['error'] ??
          'HTTP ${response.statusCode}';
      throw StateError('Supabase 登录失败：$reason');
    }
    return SupabaseSession.fromJson(decoded);
  }

  Map<String, Object?> _decodeObject(String body) {
    if (body.isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(body);
    return decoded is Map
        ? decoded.cast<String, Object?>()
        : <String, Object?>{'message': decoded.toString()};
  }

  void dispose() => _client.close();
}
