import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_exam_app/services/supabase_auth_service.dart';

void main() {
  test('邮箱密码登录使用 Supabase password grant 和 Publishable Key', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'password');
      expect(request.headers['apikey'], 'sb_publishable_test');
      expect(jsonDecode(request.body), {
        'email': 'personal@example.com',
        'password': 'secret',
      });
      return http.Response(
        jsonEncode({
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'expires_in': 3600,
          'user': {'id': 'only-user'},
        }),
        200,
      );
    });
    final service = SupabaseAuthService(client: client);
    final session = await service.signIn(
      projectUrl: Uri.parse('https://example.supabase.co'),
      publishableKey: 'sb_publishable_test',
      email: 'personal@example.com',
      password: 'secret',
    );
    expect(session.accessToken, 'access-1');
    expect(session.refreshToken, 'refresh-1');
    expect(session.userId, 'only-user');
    service.dispose();
  });

  test('刷新会话使用 Supabase refresh_token grant 并接受轮换令牌', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'refresh_token');
      expect(request.headers['apikey'], 'sb_publishable_test');
      expect(jsonDecode(request.body), {'refresh_token': 'old-refresh'});
      return http.Response(
        jsonEncode({
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'expires_at': 1800000000,
          'user': {'id': 'only-user'},
        }),
        200,
      );
    });
    final service = SupabaseAuthService(client: client);
    final session = await service.refresh(
      projectUrl: Uri.parse('https://example.supabase.co'),
      publishableKey: 'sb_publishable_test',
      refreshToken: 'old-refresh',
    );
    expect(session.accessToken, 'access-2');
    expect(session.refreshToken, 'refresh-2');
    expect(
      session.expiresAtUtc,
      DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true),
    );
    service.dispose();
  });
}
