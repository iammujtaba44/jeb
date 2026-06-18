import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:jeb/features/transactions/presentation/widgets/month_picker_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// App-bar control for changing months: step with the arrows, or tap the label
/// to jump to any month/year. "Next" is disabled on the current month.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (BuildContext context, TransactionsState _) {
        final TransactionsCubit cubit = context.read<TransactionsCubit>();
        final DateTime month = cubit.month;
        final DateTime now = DateTime.now();
        final bool atCurrentMonth =
            month.year == now.year && month.month == now.month;

        final ColorScheme scheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _NavArrow(
              icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
              onTap: cubit.goToPreviousMonth,
            ),
            const SizedBox(width: AppSpacing.xs),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                onTap: () => _pickMonth(context, cubit, month),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
            ),
            const SizedBox(width: AppSpacing.xs),
            _NavArrow(
              icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              onTap: atCurrentMonth ? null : cubit.goToNextMonth,
            ),
          ],
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

/// A compact circular step button for the month navigator. Renders faded and
/// non-interactive when [onTap] is null.
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? scheme.onSurface
                : scheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
