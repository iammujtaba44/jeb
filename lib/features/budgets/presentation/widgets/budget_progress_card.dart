import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';

/// Shows progress against the overall monthly budget: a colored bar that turns
/// amber near the limit and red when exceeded.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    required this.spent,
    required this.limit,
    required this.currencyCode,
    super.key,
  });

  final double spent;
  final double limit;
  final String currencyCode;

  static const Color _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final double ratio = limit <= 0 ? 0 : spent / limit;
    final bool over = spent > limit;
    final Color color =
        over ? scheme.error : (ratio >= 0.8 ? _amber : scheme.primary);

    final String detail = over
        ? 'Over by ${MoneyFormatter.format(spent - limit, currencyCode)}'
        : '${MoneyFormatter.format(limit - spent, currencyCode)} left · '
            '${MoneyFormatter.format(spent, currencyCode)} of ${MoneyFormatter.format(limit, currencyCode)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Monthly budget',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
