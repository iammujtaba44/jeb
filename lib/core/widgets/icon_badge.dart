import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// A rounded, color-tinted icon badge used in list tiles for a consistent
/// modern look across the app.
class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, this.color, this.size = 40, super.key});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, color: tint, size: size * 0.55),
    );
  }
}
