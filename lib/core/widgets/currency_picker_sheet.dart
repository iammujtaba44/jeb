import 'package:flutter/material.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// Shows a modal bottom sheet to choose a currency. Returns the chosen code,
/// or null if dismissed.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => _CurrencyPickerSheet(selected: selected),
  );
}

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'Select currency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: Currencies.all.length,
              itemBuilder: (BuildContext context, int index) {
                final Currency currency = Currencies.all[index];
                final bool isSelected = currency.code == selected;
                return ListTile(
                  leading: Text(
                    currency.symbol,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  title: Text(currency.code),
                  subtitle: Text(currency.name),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(currency.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
