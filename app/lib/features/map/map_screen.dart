import 'package:flutter/material.dart';

import '../../core/strings.dart';

/// Faz 1'de flutter_map + clustering ile değiştirilecek iskelet.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.tabMap)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            Strings.mapComingSoon,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
