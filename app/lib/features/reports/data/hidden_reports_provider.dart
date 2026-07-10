import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/prefs_keys.dart';

/// Kullanıcının kendi cihazında gizlediği bildirimler (Apple 1.2 içerik
/// engelleme): feed ve harita render'da bu set'e göre filtrelenir; sunucu
/// tarafındaki şikayet/auto-hide mekanizmasından bağımsız, anında etkili.
class HiddenReportsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    Future.microtask(_load);
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(PrefsKeys.hiddenReportIds) ?? const []).toSet();
  }

  Future<void> hide(String reportId) async {
    state = {...state, reportId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(PrefsKeys.hiddenReportIds, state.toList());
  }
}

final hiddenReportsProvider =
    NotifierProvider<HiddenReportsNotifier, Set<String>>(HiddenReportsNotifier.new);
