import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/prefs_keys.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../reports/data/reports_api.dart';
import '../reports/models/report.dart';

// TODO(gelecek faz): Bu servis sadece uygulama ön plandayken çalışır. Native
// background geofencing (iOS region monitoring / Android foreground service)
// ayrı, çok daha büyük bir iş — bilinçli olarak bu fazın kapsamı dışında
// bırakıldı (bkz. docs/PROGRESS.md).
const _checkInterval = Duration(seconds: 90);
const _nearbyRadiusMeters = 150.0;
// Konum etrafında taranan kabaca kare (derece cinsinden, ~1.5km).
const _scanBoxDegrees = 0.015;

final _notificationsPlugin = FlutterLocalNotificationsPlugin();

/// Foreground-only "yakındaki çukur" bildirimleri: kullanıcı bir çukurun
/// ~150m yakınından geçtiğinde tek seferlik yerel bildirim gösterir, bildirime
/// dokununca `/reports/:id` üzerinden "ben de gördüm" CTA'sı açık şekilde
/// detay sayfasına götürür (bkz. `report_detail_sheet.dart`'taki `promptConfirm`).
class GeofenceService {
  GeofenceService(this._ref);

  final Ref _ref;
  Timer? _timer;
  bool _initialized = false;

  Future<void> start() async {
    if (_timer != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(PrefsKeys.geofenceNotificationsEnabled) ?? false)) return;

    await _ensureInitialized();
    _timer = Timer.periodic(_checkInterval, (_) => _checkNearby());
    unawaited(_checkNearby());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    final reportId = response.payload;
    if (reportId != null) {
      appRouter?.push('/reports/$reportId');
    }
  }

  Future<void> _checkNearby() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final markers = await _ref.read(reportsApiProvider).getReports(
            minLng: position.longitude - _scanBoxDegrees,
            minLat: position.latitude - _scanBoxDegrees,
            maxLng: position.longitude + _scanBoxDegrees,
            maxLat: position.latitude + _scanBoxDegrees,
            status: ReportStatus.active,
          );
      if (markers.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final notified = (prefs.getStringList(PrefsKeys.geofenceNotifiedReportIds) ?? []).toSet();

      for (final marker in markers) {
        if (notified.contains(marker.id)) continue;
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          marker.lat,
          marker.lng,
        );
        if (distance > _nearbyRadiusMeters) continue;

        await _notify(marker);
        notified.add(marker.id);
      }
      await prefs.setStringList(PrefsKeys.geofenceNotifiedReportIds, notified.toList());
    } catch (_) {
      // Konum/ağ hatası — sessizce yut, bir sonraki periyodik turda tekrar dener.
    }
  }

  Future<void> _notify(ReportMarker marker) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'geofence',
        Strings.geofenceChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      marker.id.hashCode,
      Strings.geofenceNotificationTitle,
      Strings.geofenceNotificationBody,
      details,
      payload: marker.id,
    );
  }
}

final geofenceServiceProvider = Provider<GeofenceService>((ref) => GeofenceService(ref));
