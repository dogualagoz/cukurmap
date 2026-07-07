import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'report_detail_sheet.dart';

/// Geofence bildirimine dokununca açılan üst düzey route — harita ekranındaki
/// aynı bottom sheet'i (`ReportDetailSheet`, `promptConfirm: true` ile) bir
/// navigasyon hedefi olarak gösterir, kapanınca bu geçici route'u kendisi pop'lar.
class ReportDetailRouteScreen extends StatefulWidget {
  const ReportDetailRouteScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailRouteScreen> createState() => _ReportDetailRouteScreenState();
}

class _ReportDetailRouteScreenState extends State<ReportDetailRouteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReportDetailSheet(reportId: widget.reportId, promptConfirm: true),
      );
      if (mounted && context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: Colors.transparent);
}
