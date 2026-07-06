import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/severity_badge.dart';
import 'data/reports_api.dart';
import 'models/report.dart';

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
    _descriptionController.addListener(() => setState(() {}));
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
      final report = await ref.read(reportsApiProvider).createReport(
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
      context.pushReplacement('/reports/success', extra: report);
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
    final hasPhoto = widget.photoBytes != null;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              if (hasPhoto) _buildPhotoHeader(context) else _buildPlainHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(Strings.reportLocationLabel.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildLocationPicker(context),
                    const SizedBox(height: 24),
                    _sectionLabel(Strings.reportSeverityLabel.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildSeverityPicker(),
                    const SizedBox(height: 24),
                    _sectionLabel(Strings.reportCategoryLabel.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildCategoryPicker(),
                    const SizedBox(height: 24),
                    _sectionLabel(Strings.reportDescriptionLabel.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildDescriptionField(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.bgLight.withValues(alpha: 0), AppTheme.bgLight],
                  stops: const [0, 0.32],
                ),
              ),
              child: PrimaryPillButton(
                label: _submitting ? Strings.reportSubmitting : Strings.reportSubmit,
                onPressed: _position == null || _submitting ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTheme.mono(color: AppTheme.textSecondaryLight));

  Widget _buildPhotoHeader(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          child: Image.memory(widget.photoBytes!, height: 290, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.42), Colors.transparent],
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _circleBackButton(context),
                const SizedBox(width: 12),
                Text(
                  Strings.reportFormTitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlainHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            _circleBackButton(context, dark: true),
            const SizedBox(width: 12),
            Text(Strings.reportFormTitle, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 19, color: AppTheme.bgDark)),
          ],
        ),
      ),
    );
  }

  Widget _circleBackButton(BuildContext context, {bool dark = false}) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark ? AppTheme.bgDark.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.bgDark),
      ),
    );
  }

  Widget _buildLocationPicker(BuildContext context) {
    if (_locating) {
      return const SizedBox(height: 132, child: Center(child: CircularProgressIndicator()));
    }
    if (_position == null) {
      return SizedBox(
        height: 132,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_locationError ?? Strings.locationPermissionDenied, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _locate, child: const Text(Strings.retry)),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 132,
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
              child: Icon(Icons.location_pin, size: 40, color: severityColor(_severity)),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  Strings.reportAdjustPin,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.bgDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityPicker() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.7,
      children: [
        for (final level in const [1, 2, 3, 4])
          _SeverityCard(
            severity: level,
            selected: _severity == level,
            onTap: () => setState(() => _severity = level),
          ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (final entry in _categoryLabels.entries)
          _CategoryPill(
            label: entry.value,
            selected: _category == entry.key,
            onTap: () => setState(() => _category = entry.key),
          ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _descriptionController,
            maxLength: 280,
            maxLines: 3,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: Strings.reportDescriptionHint,
              border: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
          ),
          Text(
            '${_descriptionController.text.length}/280',
            style: AppTheme.mono(color: AppTheme.textSecondaryLight, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SeverityCard extends StatelessWidget {
  const _SeverityCard({required this.severity, required this.selected, required this.onTap});

  final int severity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.black.withValues(alpha: 0.07), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            SeverityDot(severity: severity, size: 14),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    severityLabel(severity),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 14, color: AppTheme.bgDark),
                  ),
                  Text('Seviye $severity', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.bgDark : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: selected ? null : Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.bgLight : AppTheme.textSecondaryLightAlt,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
