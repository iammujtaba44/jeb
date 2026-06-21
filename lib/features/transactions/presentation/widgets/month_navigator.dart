import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:jeb/features/transactions/presentation/widgets/month_picker_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// App-bar control for changing months: tap to jump to any month/year via the
/// picker. A single, tappable pill — no stepper arrows to crowd the bar.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (BuildContext context, TransactionsState _) {
        final TransactionsCubit cubit = context.read<TransactionsCubit>();
        final DateTime month = cubit.month;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () => _pickMonth(context, cubit, month),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    PhosphorIcons.calendarBlank(PhosphorIconsStyle.bold),
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.monthYear(month),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMonth(
    BuildContext context,
    TransactionsCubit cubit,
    DateTime current,
  ) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => MonthPickerDialog(initialMonth: current),
    );
    if (picked != null) {
      await cubit.goToMonth(picked);
    }
  }
}
