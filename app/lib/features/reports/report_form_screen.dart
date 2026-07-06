import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'data/reports_api.dart';
import 'models/report.dart';

const _severityLabels = {
  1: Strings.severity1,
  2: Strings.severity2,
  3: Strings.severity3,
  4: Strings.severity4,
};

const _categoryLabels = {
  ReportCategory.cukur: Strings.categoryCukur,
  ReportCategory.bozukAsfalt: Strings.categoryBozukAsfalt,
  ReportCategory.rogar: Strings.categoryRogar,
  ReportCategory.kasis: Strings.categoryKasis,
  ReportCategory.diger: Strings.categoryDiger,
};

/// Kamera akışından (fotoğraflı) veya doğrudan "fotoğrafsız bildir"den
/// gelinen rapor formu: konum, tehlike seviyesi, kategori, açıklama.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.photoBytes});

  final Uint8List? photoBytes;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _descriptionController = TextEditingController();

  LatLng? _position;
  bool _locating = true;
  String? _locationError;
  int _severity = 2;
  ReportCategory _category = ReportCategory.cukur;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationError = Strings.locationPermissionDenied;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = LatLng(position.latitude, position.longitude);
        _locating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = Strings.locationPermissionDenied;
      });
    }
  }

  Future<void> _submit() async {
    final position = _position;
    if (position == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(reportsApiProvider).createReport(
            lat: position.latitude,
            lng: position.longitude,
            severity: _severity,
            category: _category,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            photoBytes: widget.photoBytes,
          );
      if (!mounted) return;
      ref.invalidate(reportMarkersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.reportSuccess)),
      );
      context.go('/map');
    } on ReportConflictException catch (e) {
      if (!mounted) return;
      await _showDuplicateDialog(e);
    } on DioException catch (e) {
      if (!mounted) return;
      final message =
          e.response?.statusCode == 429 ? Strings.reportErrorRateLimit : Strings.reportErrorGeneric;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.reportErrorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showDuplicateDialog(ReportConflictException e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Strings.duplicateTitle),
        content: Text(e.message.isNotEmpty ? e.message : Strings.duplicateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Strings.duplicateCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Strings.duplicateConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(reportsApiProvider).vote(e.nearbyReportId, VoteType.confirm);
      if (!mounted) return;
      ref.invalidate(reportMarkersProvider);
      context.go('/map');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.voteError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.reportFormTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.photoBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.photoBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildLocationPicker(context),
          const SizedBox(height: 24),
          Text(Strings.reportSeverityLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildSeverityPicker(),
          const SizedBox(height: 24),
          Text(Strings.reportCategoryLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildCategoryPicker(),
          const SizedBox(height: 24),
          Text(Strings.reportDescriptionLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLength: 280,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: Strings.reportDescriptionHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _position == null || _submitting ? null : _submit,
            child: Text(_submitting ? Strings.reportSubmitting : Strings.reportSubmit),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker(BuildContext context) {
    if (_locating) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_position == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _locationError ?? Strings.locationPermissionDenied,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _locate, child: const Text(Strings.retry)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _position!,
                    initialZoom: 17,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) setState(() => _position = camera.center);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cukurmap.app',
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Icon(
                    Icons.location_pin,
                    size: 40,
                    color: AppTheme.severityColors[_severity],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(Strings.reportAdjustPin, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSeverityPicker() {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in _severityLabels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: _severity == entry.key,
            selectedColor: AppTheme.severityColors[entry.key]?.withValues(alpha: 0.5),
            onSelected: (_) => setState(() => _severity = entry.key),
          ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in _categoryLabels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: _category == entry.key,
            onSelected: (_) => setState(() => _category = entry.key),
          ),
      ],
    );
  }
}
