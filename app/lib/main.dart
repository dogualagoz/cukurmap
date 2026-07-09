import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/prefs_keys.dart';
import 'core/router.dart';
import 'core/strings.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Koşul kabulü sonradan eklendi: eski kurulumlar da koşulları bir kez görsün.
  final onboarded = (prefs.getBool(PrefsKeys.hasSeenOnboarding) ?? false) &&
      (prefs.getBool(PrefsKeys.termsAcceptedV1) ?? false);
  final router = buildRouter(onboarded ? '/camera' : '/onboarding');
  runApp(ProviderScope(child: CukurMapApp(router: router)));
}

class CukurMapApp extends ConsumerWidget {
  const CukurMapApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: Strings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
