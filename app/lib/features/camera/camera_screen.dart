import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _permissionDenied = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _permanentlyDenied = status.isPermanentlyDenied;
          });
        }
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      final future = controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializeFuture = future;
      });
    } catch (_) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _setup();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      context.push('/reports/new', extra: bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.reportErrorGeneric)),
      );
    }
  }

  void _reportWithoutPhoto() => context.push('/reports/new');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_permissionDenied) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, size: 72, color: AppTheme.textSecondaryDark),
                const SizedBox(height: 16),
                Text(
                  Strings.cameraPermissionDenied,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 24),
                PrimaryPillButton(label: Strings.reportWithoutPhoto, onPressed: _reportWithoutPhoto, height: 52),
                if (_permanentlyDenied) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: openAppSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.bgLight,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(Strings.openSettings),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    final initializeFuture = _initializeFuture;
    if (controller == null || initializeFuture == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 196,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          Strings.cameraFrameHint,
                          style: TextStyle(color: AppTheme.bgLight, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _reportWithoutPhoto,
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.accent),
                          label: const Text(Strings.reportWithoutPhoto),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.bgLight,
                            backgroundColor: AppTheme.bgDark.withValues(alpha: 0.45),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _capture,
                                child: const _PulsingShutter(),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                Strings.cameraShutterLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: const Center(
                              child: Text(Strings.cameraAutoLabel, style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsingShutter extends StatefulWidget {
  const _PulsingShutter();

  @override
  State<_PulsingShutter> createState() => _PulsingShutterState();
}

class _PulsingShutterState extends State<_PulsingShutter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accent, width: 4),
        boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.35), blurRadius: 22)],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final scale = 1 - (0.08 * t);
          final opacity = 1 - (0.18 * t);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: const DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent),
        ),
      ),
    );
  }
}
