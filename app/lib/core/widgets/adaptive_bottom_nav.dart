import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../strings.dart';
import '../theme.dart';

/// Mockup'ta her ekran kendi zeminine göre (Kamera/Çukur Ligi koyu,
/// Harita/Profil açık) bir alt nav çiziyor. Sekmeler go_router'ın paylaşılan
/// tab shell'i içinde render edildiği için burada aktif sekmeye göre renk
/// şemasını uyarlıyoruz.
class AdaptiveBottomNav extends StatelessWidget {
  const AdaptiveBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _darkTabs = {0, 3}; // 0 kamera, 3 çukur ligi

  static const _items = [
    (icon: Icons.photo_camera_outlined, selectedIcon: Icons.photo_camera, label: Strings.tabCamera),
    (icon: Icons.map_outlined, selectedIcon: Icons.map, label: Strings.tabMap),
    (icon: Icons.dynamic_feed_outlined, selectedIcon: Icons.dynamic_feed, label: Strings.tabFeed),
    (icon: Icons.emoji_events_outlined, selectedIcon: Icons.emoji_events, label: Strings.tabStats),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: Strings.tabProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = _darkTabs.contains(currentIndex);
    final bg = isDark ? AppTheme.bgDark : AppTheme.bgLight;
    final activeColor = isDark ? AppTheme.accent : AppTheme.bgDark;
    final inactiveColor = isDark ? AppTheme.textSecondaryDarkAlt : AppTheme.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  item: _items[i],
                  selected: i == currentIndex,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final ({IconData icon, IconData selectedIcon, String label}) item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? item.selectedIcon : item.icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: selected
                ? GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: color)
                : GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
