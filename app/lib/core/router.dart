import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/camera_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/geofence/geofence_service.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reports/models/report.dart';
import '../features/reports/report_detail_route_screen.dart';
import '../features/reports/report_form_screen.dart';
import '../features/reports/report_success_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import 'widgets/adaptive_bottom_nav.dart';

/// Geofence bildirimine dokunulduğunda widget ağacı dışından (plugin
/// callback'i) navigasyon yapabilmek için son oluşturulan router burada
/// tutulur — bkz. `geofence_service.dart`.
GoRouter? appRouter;

/// [initialLocation] main.dart'ta shared_preferences'taki "ilk açılış"
/// bayrağına göre hesaplanır: görülmediyse '/onboarding', görüldüyse '/camera'.
GoRouter buildRouter(String initialLocation) {
  final router = GoRouter(
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
      GoRoute(
        path: '/reports/:id',
        builder: (_, state) => ReportDetailRouteScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
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
            GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
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
  appRouter = router;
  return router;
}

class _TabShell extends ConsumerStatefulWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<_TabShell> with WidgetsBindingObserver {
  late final GeofenceService _geofenceService;

  @override
  void initState() {
    super.initState();
    _geofenceService = ref.read(geofenceServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    _geofenceService.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _geofenceService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _geofenceService.start();
    } else if (state == AppLifecycleState.paused) {
      _geofenceService.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: AdaptiveBottomNav(
        currentIndex: widget.shell.currentIndex,
        onTap: (index) => widget.shell.goBranch(
          index,
          initialLocation: index == widget.shell.currentIndex,
        ),
      ),
    );
  }
}
