import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../models/user_profile.dart';

class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  Future<UserProfile> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserProfile.fromJson(response.data!);
  }

  Future<void> deleteAccount() async {
    await _dio.delete<void>('/users/me');
  }

  Future<UserProfile> updateNickname(String nickname) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/users/me',
      data: {'nickname': nickname},
    );
    return UserProfile.fromJson(response.data!);
  }
}

final usersApiProvider = Provider<UsersApi>((ref) {
  return UsersApi(ref.watch(authedDioProvider));
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  final api = ref.watch(usersApiProvider);
  return api.me();
});
