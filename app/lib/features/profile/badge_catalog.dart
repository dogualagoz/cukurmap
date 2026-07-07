import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../users/models/user_profile.dart';

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.criteria,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(UserProfile profile) criteria;
}

/// Rozet kataloğu — kilit/açık durumu gerçek kullanıcı istatistiklerinden
/// (bkz. `UserProfile`, `GET /users/me`) hesaplanır.
final badgeCatalog = <BadgeDefinition>[
  BadgeDefinition(
    id: 'first_report',
    title: Strings.badgeFirstReport,
    description: Strings.badgeFirstReportDesc,
    icon: Icons.emoji_events,
    criteria: (p) => p.reportCount >= 1,
  ),
  BadgeDefinition(
    id: 'reports_10',
    title: Strings.badge10Reports,
    description: Strings.badge10ReportsDesc,
    icon: Icons.emoji_events,
    criteria: (p) => p.reportCount >= 10,
  ),
  BadgeDefinition(
    id: 'reports_50',
    title: Strings.badge50Reports,
    description: Strings.badge50ReportsDesc,
    icon: Icons.emoji_events,
    criteria: (p) => p.reportCount >= 50,
  ),
  BadgeDefinition(
    id: 'reports_100',
    title: Strings.badge100Reports,
    description: Strings.badge100ReportsDesc,
    icon: Icons.emoji_events,
    criteria: (p) => p.reportCount >= 100,
  ),
  BadgeDefinition(
    id: 'neighborhood_watch',
    title: Strings.badgeNeighborhoodWatch,
    description: Strings.badgeNeighborhoodWatchDesc,
    icon: Icons.shield_outlined,
    criteria: (p) => p.confirmsGiven >= 20,
  ),
  BadgeDefinition(
    id: 'municipality_mover',
    title: Strings.badgeMunicipalityMover,
    description: Strings.badgeMunicipalityMoverDesc,
    icon: Icons.construction_outlined,
    criteria: (p) => p.fixedReportCount >= 1,
  ),
  BadgeDefinition(
    id: 'trusted_observer',
    title: Strings.badgeTrustedObserver,
    description: Strings.badgeTrustedObserverDesc,
    icon: Icons.verified_outlined,
    criteria: (p) => p.confirmsReceived >= 10,
  ),
  BadgeDefinition(
    id: 'viral',
    title: Strings.badgeViralLocked,
    description: Strings.badgeViralLockedDesc,
    icon: Icons.local_fire_department_outlined,
    // Faz 4'teki upvote sayaçları eklenene kadar kilitli kalır.
    criteria: (_) => false,
  ),
];
