import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/api_client.dart';

const _kDeviceIdKey = 'device_id';
const _kTokenKey = 'auth_token';
const _kNicknameKey = 'nickname';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.nickname,
  });

  final String token;
  final String userId;
  final String nickname;
}

/// Cihaz UUID'si üretir (donanım kimliği DEĞİL — rastgele, sadece bu
/// uygulamaya ait), sunucudan anonim JWT alır. Sunucuya ulaşılamazsa
/// son bilinen oturumu kullanır.
class AuthNotifier extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    final storage = ref.read(secureStorageProvider);

    var deviceId = await storage.read(key: _kDeviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await storage.write(key: _kDeviceIdKey, value: deviceId);
    }

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/anonymous',
        data: {'deviceId': deviceId},
      );
      final body = response.data!;
      final user = body['user'] as Map<String, dynamic>;
      final session = AuthSession(
        token: body['token'] as String,
        userId: user['id'] as String,
        nickname: user['nickname'] as String,
      );
      await storage.write(key: _kTokenKey, value: session.token);
      await storage.write(key: _kNicknameKey, value: session.nickname);
      return session;
    } on DioException {
      // Offline fallback: cache'lenmiş oturum varsa onunla devam et
      final cachedToken = await storage.read(key: _kTokenKey);
      final cachedNickname = await storage.read(key: _kNicknameKey);
      if (cachedToken != null && cachedNickname != null) {
        return AuthSession(
          token: cachedToken,
          userId: '',
          nickname: cachedNickname,
        );
      }
      rethrow;
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession>(
  AuthNotifier.new,
);

/// Yetkili istekler için Authorization header'lı Dio.
final authedDioProvider = Provider<Dio>((ref) {
  final dio = ref.watch(dioProvider);
  final session = ref.watch(authProvider).valueOrNull;
  final authed = Dio(dio.options);
  if (session != null) {
    authed.options.headers['Authorization'] = 'Bearer ${session.token}';
  }
  return authed;
});
