import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';

/// Hero card showing the month's balance, with income and expense pills.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currencyCode,
    this.budgetLimit,
    super.key,
  });

  final double income;
  final double expense;
  final double balance;
  final String currencyCode;

  /// Overall monthly budget; when set, a progress meter is shown in-card.
  final double? budgetLimit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.45), scheme.primary),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Balance this month',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: balance),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, _) => Text(
              MoneyFormatter.compact(value, currencyCode),
              style: textTheme.displaySmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryPill(
                  icon: Icons.south_west,
                  label: 'Income',
                  value: MoneyFormatter.compact(income, currencyCode),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SummaryPill(
                  icon: Icons.north_east,
                  label: 'Expense',
                  value: MoneyFormatter.compact(expense, currencyCode),
                ),
              ),
            ],
          ),
          if (income > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _SavingsTile(
              income: income,
              expense: expense,
              balance: balance,
              currencyCode: currencyCode,
            ),
          ],
          if (budgetLimit != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: scheme.onPrimary.withValues(alpha: 0.18)),
            const SizedBox(height: AppSpacing.md),
            _BudgetMeter(
              spent: expense,
              limit: budgetLimit!,
              currencyCode: currencyCode,
            ),
          ],
        ],
      ),
    );
  }
}

/// Highlights how much of this month's income was kept — the savings rate
/// plus the saved amount — flipping to an "overspent" state when expenses
/// exceed income. Only shown when there is income to measure against.
class _SavingsTile extends StatelessWidget {
  const _SavingsTile({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currencyCode,
  });

  final double income;
  final double expense;
  final double balance;
  final String currencyCode;

  static const Color _red = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onPrimary = scheme.onPrimary;

    final bool saving = balance >= 0;
    final int rate = ((balance.abs() / income) * 100).round();
    final String label =
        saving ? 'Saved $rate% of income' : 'Overspent by $rate% of income';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            saving ? Icons.savings_outlined : Icons.warning_amber_rounded,
            size: 20,
            color: saving ? onPrimary : _red,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${saving ? '' : '-'}${MoneyFormatter.compact(balance.abs(), currencyCode)}',
            style: textTheme.titleMedium?.copyWith(
              color: saving ? onPrimary : _red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// In-card monthly-budget meter, tinted to read against the gradient.
class _BudgetMeter extends StatelessWidget {
  const _BudgetMeter({
    required this.spent,
    required this.limit,
    required this.currencyCode,
  });

  final double spent;
  final double limit;
  final String currencyCode;

  // Lighter shades so the state still reads on the primary gradient.
  static const Color _amber = Color(0xFFFCD34D);
  static const Color _red = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onPrimary = scheme.onPrimary;

    final double ratio = limit <= 0 ? 0 : spent / limit;
    final bool over = spent > limit;
    final Color barColor = over ? _red : (ratio >= 0.8 ? _amber : onPrimary);

    final String detail = over
        ? 'Over by ${MoneyFormatter.compact(spent - limit, currencyCode)}'
        : '${MoneyFormatter.compact(limit - spent, currencyCode)} left of '
            '${MoneyFormatter.compact(limit, currencyCode)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Monthly budget',
              style: textTheme.labelMedium?.copyWith(
                color: onPrimary.withValues(alpha: 0.85),
              ),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: textTheme.labelLarge?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, _) =>
                LinearProgressIndicator(
              value: value,
              color: barColor,
              backgroundColor: onPrimary.withValues(alpha: 0.22),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          style: textTheme.bodySmall?.copyWith(
            color: onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onPrimary = scheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: onPrimary.withValues(alpha: 0.9)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
