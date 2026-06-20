import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// Visual tone of a snackbar.
enum SnackType { info, success, error }

/// A single, consistently-styled snackbar used across the app: floating,
/// rounded, with a leading icon and an optional action.
abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (type) {
      SnackType.success => (
          const Color(0xFF16A34A),
          Colors.white,
          Icons.check_circle_rounded,
        ),
      SnackType.error => (scheme.error, scheme.onError, Icons.error_rounded),
      SnackType.info => (
          scheme.inverseSurface,
          scheme.onInverseSurface,
          Icons.info_rounded,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: duration,
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: fg,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}
