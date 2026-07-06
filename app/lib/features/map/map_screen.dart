import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/severity_badge.dart';
import '../reports/data/reports_api.dart';
import '../reports/models/report.dart';
import '../reports/report_detail_sheet.dart';

const _turkeyCenter = LatLng(39.0, 35.0);

const ReportsQuery _initialQuery = (
  minLng: 25.0,
  minLat: 35.5,
  maxLng: 45.0,
  maxLat: 42.5,
  severity: null,
  status: null,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  Timer? _debounce;
  ReportsQuery _query = _initialQuery;
  int? _severityFilter;
  ReportStatus? _statusFilter;
  bool _locating = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final bounds = camera.visibleBounds;
      setState(() {
        _query = (
          minLng: bounds.west,
          minLat: bounds.south,
          maxLng: bounds.east,
          maxLat: bounds.north,
          severity: _severityFilter,
          status: _statusFilter,
        );
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _query = (
        minLng: _query.minLng,
        minLat: _query.minLat,
        maxLng: _query.maxLng,
        maxLat: _query.maxLat,
        severity: _severityFilter,
        status: _statusFilter,
      );
    });
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (_) {
      // sessizce yut — konum alınamazsa kullanıcı haritayı elle kaydırabilir.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showDetail(String reportId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportDetailSheet(reportId: reportId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(reportMarkersProvider(_query));
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _turkeyCenter,
              initialZoom: 6,
              onPositionChanged: _onPositionChanged,
              onMapReady: () => _onPositionChanged(_mapController.camera, false),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cukurmap.app',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  size: const Size(44, 44),
                  markers: [
                    for (final marker in markersAsync.valueOrNull ?? const [])
                      Marker(
                        key: ValueKey(marker.id),
                        point: LatLng(marker.lat, marker.lng),
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showDetail(marker.id),
                          child: _MapPin(severity: marker.severity),
                        ),
                      ),
                  ],
                  builder: (context, clusterMarkers) => Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(
                        '${clusterMarkers.length}',
                        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(bottom: false, child: _buildTopBar()),
          ),
          Positioned(
            right: 16,
            bottom: 26,
            child: _LocateButton(loading: _locating, onTap: _goToMyLocation),
          ),
          if (markersAsync.isLoading)
            const Positioned(
              bottom: 16,
              left: 16,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
              ),
            ),
          if (markersAsync.valueOrNull?.isEmpty ?? false)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Strings.emptyMap, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: AppTheme.textSecondaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  Strings.mapSearchHint,
                  style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterPill(label: Strings.filterAll, selected: _severityFilter == null, onTap: () {
                _severityFilter = null;
                _applyFilters();
              }),
              const SizedBox(width: 8),
              for (final severity in const [1, 2, 3, 4])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: severityLabel(severity),
                    selected: _severityFilter == severity,
                    color: severityColor(severity),
                    onTap: () {
                      _severityFilter = severity;
                      _applyFilters();
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterPill(label: Strings.filterAll, selected: _statusFilter == null, onTap: () {
                _statusFilter = null;
                _applyFilters();
              }),
              const SizedBox(width: 8),
              _FilterPill(
                label: Strings.statusActive,
                selected: _statusFilter == ReportStatus.active,
                onTap: () {
                  _statusFilter = ReportStatus.active;
                  _applyFilters();
                },
              ),
              const SizedBox(width: 8),
              _FilterPill(
                label: Strings.statusFixed,
                selected: _statusFilter == ReportStatus.fixed,
                onTap: () {
                  _statusFilter = ReportStatus.fixed;
                  _applyFilters();
                },
              ),
              const SizedBox(width: 8),
              _FilterPill(
                label: Strings.statusHidden,
                selected: _statusFilter == ReportStatus.hidden,
                onTap: () {
                  _statusFilter = ReportStatus.hidden;
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: severityColor(severity),
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(13),
              topRight: Radius.circular(13),
              bottomLeft: Radius.circular(13),
              bottomRight: Radius.circular(3),
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap, this.color});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.bgDark : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.bgLight : AppTheme.bgDark,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                )
              : const Icon(Icons.my_location, color: AppTheme.bgDark),
        ),
      ),
    );
  }
}
