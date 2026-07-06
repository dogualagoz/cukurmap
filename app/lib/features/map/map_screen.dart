import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../reports/data/reports_api.dart';
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
          status: null,
        );
      });
    });
  }

  void _setSeverityFilter(int? severity) {
    setState(() {
      _severityFilter = severity;
      _query = (
        minLng: _query.minLng,
        minLat: _query.minLat,
        maxLng: _query.maxLng,
        maxLat: _query.maxLat,
        severity: severity,
        status: _query.status,
      );
    });
  }

  void _showDetail(String reportId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportDetailSheet(reportId: reportId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markersAsync = ref.watch(reportMarkersProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.tabMap)),
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
                  size: const Size(36, 36),
                  markers: [
                    for (final marker in markersAsync.valueOrNull ?? const [])
                      Marker(
                        key: ValueKey(marker.id),
                        point: LatLng(marker.lat, marker.lng),
                        width: 32,
                        height: 32,
                        child: GestureDetector(
                          onTap: () => _showDetail(marker.id),
                          child: Icon(
                            Icons.location_pin,
                            color: AppTheme.severityColors[marker.severity],
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                  builder: (context, clusterMarkers) => CircleAvatar(
                    backgroundColor: AppTheme.accent,
                    child: Text(
                      '${clusterMarkers.length}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildFilterBar(),
          ),
          if (markersAsync.isLoading)
            const Positioned(
              bottom: 16,
              right: 16,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text(Strings.filterAll),
            selected: _severityFilter == null,
            onSelected: (_) => _setSeverityFilter(null),
          ),
          const SizedBox(width: 8),
          for (final severity in const [1, 2, 3, 4])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_severityLabel(severity)),
                selected: _severityFilter == severity,
                selectedColor: AppTheme.severityColors[severity]?.withValues(alpha: 0.6),
                onSelected: (_) => _setSeverityFilter(severity),
              ),
            ),
        ],
      ),
    );
  }

  String _severityLabel(int severity) => switch (severity) {
        1 => Strings.severity1,
        2 => Strings.severity2,
        3 => Strings.severity3,
        _ => Strings.severity4,
      };
}
