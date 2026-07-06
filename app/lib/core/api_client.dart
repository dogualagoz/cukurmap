import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dev ortamında Android emülatörü host makineye 10.0.2.2 ile ulaşır.
/// Gerçek cihazda test için --dart-define=API_BASE_URL=http://MAC_IP:3000/api/v1
String defaultBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
  return 'http://localhost:3000/api/v1';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: defaultBaseUrl(),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  return dio;
});

/// `/uploads/...` gibi relative dönen fotoğraf yollarını tam URL'e çevirmek
/// için sunucu origin'i (scheme+host+port, `/api/v1` prefix'i olmadan).
final apiOriginProvider = Provider<String>((ref) {
  final baseUrl = ref.watch(dioProvider).options.baseUrl;
  return Uri.parse(baseUrl).replace(path: '', query: '').toString();
});
