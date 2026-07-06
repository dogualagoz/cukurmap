import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/camera_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reports/models/report.dart';
import '../features/reports/report_form_screen.dart';
import '../features/reports/report_success_screen.dart';
import '../features/stats/stats_screen.dart';
import 'widgets/adaptive_bottom_nav.dart';

/// [initialLocation] main.dart'ta shared_preferences'taki "ilk açılış"
/// bayrağına göre hesaplanır: görülmediyse '/onboarding', görüldüyse '/camera'.
GoRouter buildRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/reports/new',
          builder: (_, state) => ReportFormScreen(photoBytes: state.extra as Uint8List?),
        ),
        GoRoute(
          path: '/reports/success',
          builder: (_, state) => ReportSuccessScreen(report: state.extra as ReportDetail),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _TabShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/camera', builder: (_, __) => const CameraScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AdaptiveBottomNav(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
