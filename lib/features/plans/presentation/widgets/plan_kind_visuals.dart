import 'package:flutter/material.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Icon + accent colour for each plan kind (kept out of the domain entity).
abstract final class PlanKindVisuals {
  static IconData icon(PlanKind kind) => switch (kind) {
        PlanKind.asset => PhosphorIcons.buildings(PhosphorIconsStyle.duotone),
        PlanKind.loan => PhosphorIcons.bank(PhosphorIconsStyle.duotone),
        PlanKind.giving => PhosphorIcons.handHeart(PhosphorIconsStyle.duotone),
      };

  static Color color(PlanKind kind) => switch (kind) {
        PlanKind.asset => const Color(0xFF0D9488), // teal
        PlanKind.loan => const Color(0xFFF59E0B), // amber
        PlanKind.giving => const Color(0xFFE11D48), // rose
      };
}
