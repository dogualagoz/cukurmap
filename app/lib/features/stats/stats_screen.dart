import 'package:flutter/material.dart';

import '../../core/strings.dart';

/// Faz 2'de Çukur Ligi ile değiştirilecek iskelet.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.tabStats)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            Strings.statsComingSoon,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
