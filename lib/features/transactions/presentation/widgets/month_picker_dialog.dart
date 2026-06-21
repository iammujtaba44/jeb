import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// Dialog for jumping to any month/year. Returns the first day of the chosen
/// month, or null if dismissed. Future months are disabled.
class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({required this.initialMonth, this.title, super.key});

  final DateTime initialMonth;

  /// Optional heading, e.g. "Start month" / "End month".
  final String? title;

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool canGoNextYear = _year < now.year;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.title != null) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canGoNextYear ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: List<Widget>.generate(12, (int index) {
                final int month = index + 1;
                final bool isFuture = _year > now.year ||
                    (_year == now.year && month > now.month);
                final bool isSelected = _year == widget.initialMonth.year &&
                    month == widget.initialMonth.month;
                return _MonthChip(
                  label: DateFormat.MMM().format(DateTime(_year, month)),
                  selected: isSelected,
                  enabled: !isFuture,
                  onTap: () =>
                      Navigator.of(context).pop(DateTime(_year, month)),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: selected,
        onSelected: enabled ? (_) => onTap() : null,
      ),
    );
  }
}
