import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// Confirmation before a destructive swipe/delete. Resolves to true only when
/// the user explicitly taps Delete (false on Cancel, barrier tap, or back).
Future<bool> confirmDelete(
  BuildContext context, {
  String title = 'Delete transaction?',
  String message = 'This will remove it from your records.',
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
