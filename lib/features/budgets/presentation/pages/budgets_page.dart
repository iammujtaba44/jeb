import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/currencies.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/core/widgets/icon_badge.dart';
import 'package:jeb/features/budgets/presentation/cubit/budgets_cubit.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_avatar.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BudgetsCubit>(
      create: (_) => getIt<BudgetsCubit>()..load(),
      child: const BudgetsView(),
    );
  }
}

class BudgetsView extends StatelessWidget {
  const BudgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: BlocBuilder<BudgetsCubit, BudgetsState>(
        builder: (BuildContext context, BudgetsState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final String currency = state.currency;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const _SectionLabel('Overall'),
              Card(
                child: _OverallBudgetTile(
                  limit: state.overallLimit,
                  spent: state.totalSpent,
                  currency: currency,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Per category'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < state.categories.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, indent: 64),
                      _CategoryBudgetTile(
                        category: state.categories[i],
                        limit: state.categoryLimits[state.categories[i].id],
                        spent: state.spentFor(state.categories[i].id),
                        currency: currency,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OverallBudgetTile extends StatelessWidget {
  const _OverallBudgetTile({
    required this.limit,
    required this.spent,
    required this.currency,
  });

  final double? limit;
  final double spent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return _BudgetRow(
      leading: const IconBadge(icon: Icons.account_balance_wallet_outlined),
      title: 'Monthly budget',
      spent: spent,
      limit: limit,
      currency: currency,
      onTap: () async {
        final double? result = await showBudgetDialog(
          context,
          title: 'Overall budget',
          initial: limit,
          currency: currency,
        );
        if (result != null && context.mounted) {
          context.read<BudgetsCubit>().setOverall(result);
        }
      },
    );
  }
}

class _CategoryBudgetTile extends StatelessWidget {
  const _CategoryBudgetTile({
    required this.category,
    required this.limit,
    required this.spent,
    required this.currency,
  });

  final Category category;
  final double? limit;
  final double spent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return _BudgetRow(
      leading: CategoryAvatar(category: category, radius: 18),
      title: category.name,
      spent: spent,
      limit: limit,
      currency: currency,
      onTap: () async {
        final double? result = await showBudgetDialog(
          context,
          title: category.name,
          initial: limit,
          currency: currency,
        );
        if (result != null && context.mounted) {
          context.read<BudgetsCubit>().setCategory(category.id, result);
        }
      },
    );
  }
}

/// A budget list row: shows a progress bar + over/under when a [limit] is set,
/// or just the amount spent this month when it isn't.
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.leading,
    required this.title,
    required this.spent,
    required this.limit,
    required this.currency,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final double spent;
  final double? limit;
  final String currency;
  final VoidCallback onTap;

  static const Color _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double? lim = limit;
    final bool budgeted = lim != null && lim > 0;

    final double ratio = budgeted ? spent / lim : 0;
    final bool over = budgeted && spent > lim;
    final Color color =
        over ? scheme.error : (ratio >= 0.8 ? _amber : scheme.primary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (over)
                  _Pill(label: 'Exceeded', color: scheme.error)
                else if (budgeted)
                  Text(
                    '${(ratio * 100).round()}%',
                    style: textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (budgeted) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                over
                    ? 'Over by ${MoneyFormatter.format(spent - lim, currency)} · '
                        '${MoneyFormatter.format(spent, currency)} of '
                        '${MoneyFormatter.format(lim, currency)}'
                    : '${MoneyFormatter.format(spent, currency)} of '
                        '${MoneyFormatter.format(lim, currency)} · '
                        '${MoneyFormatter.format(lim - spent, currency)} left',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else
              Text(
                spent > 0
                    ? 'Spent ${MoneyFormatter.format(spent, currency)} this month · tap to set a budget'
                    : 'No budget · tap to set one',
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Future<double?> showBudgetDialog(
  BuildContext context, {
  required String title,
  required double? initial,
  required String currency,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) =>
        _BudgetEditDialog(title: title, initial: initial, currency: currency),
  );
}

class _BudgetEditDialog extends StatefulWidget {
  const _BudgetEditDialog({
    required this.title,
    required this.initial,
    required this.currency,
  });

  final String title;
  final double? initial;
  final String currency;

  @override
  State<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<_BudgetEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final double? initial = widget.initial;
    _controller = TextEditingController(
      text: initial == null
          ? ''
          : (initial % 1 == 0 ? initial.toInt().toString() : '$initial'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context)
      .pop(double.tryParse(_controller.text.trim()) ?? 0);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String symbol = Currencies.byCode(widget.currency).symbol;
    final bool hasExisting = widget.initial != null && widget.initial != 0;

    // Built entirely from AlertDialog's native title/content/actions slots and
    // with NO flex widgets (Spacer/Expanded) in the layout, so it cannot hit
    // the "BoxConstraints forces an infinite width" crash regardless of how
    // the route is hosted (e.g. inside an IndexedStack tab's overlay).
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 22,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Monthly limit',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        onSubmitted: (_) => _save(),
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          prefixText: '$symbol ',
          prefixStyle: textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          hintText: '0',
          hintStyle: textTheme.headlineSmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
        ),
      ),
      actionsAlignment:
          hasExisting ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      actions: <Widget>[
        if (hasExisting)
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop<double>(0),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
