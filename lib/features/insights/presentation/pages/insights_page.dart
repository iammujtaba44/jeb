import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/insights/presentation/cubit/insights_cubit.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InsightsCubit>(
      create: (_) => getIt<InsightsCubit>()..load(),
      child: const InsightsView(),
    );
  }
}

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (BuildContext context, InsightsState state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _RangeSelector(selected: state.rangeMonths),
              const SizedBox(height: AppSpacing.lg),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.months.every((MonthStat m) =>
                  m.expense == 0 && m.income == 0))
                const _EmptyState()
              else ...<Widget>[
                _TotalsCard(state: state),
                const SizedBox(height: AppSpacing.lg),
                _TrendCard(state: state),
                const SizedBox(height: AppSpacing.lg),
                _BudgetCheckCard(state: state),
                if (state.topCategories.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  _TopCategoriesCard(state: state),
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: <ButtonSegment<int>>[
          for (final int m in InsightsCubit.ranges)
            ButtonSegment<int>(value: m, label: Text('${m}M')),
        ],
        selected: <int>{selected},
        onSelectionChanged: (Set<int> s) =>
            context.read<InsightsCubit>().setRange(s.first),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String cur = state.currency;
    final bool positiveSavings = state.totalSavings >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Last ${state.rangeMonths} months',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Stat(
                    label: 'Income',
                    value: MoneyFormatter.format(state.totalIncome, cur),
                    color: const Color(0xFF16A34A),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Spending',
                    value: MoneyFormatter.format(state.totalSpending, cur),
                    color: scheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Stat(
                    label: 'Savings',
                    value: MoneyFormatter.format(state.totalSavings, cur),
                    color: positiveSavings
                        ? const Color(0xFF16A34A)
                        : scheme.error,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Budget',
                    value: state.totalBudget == null
                        ? 'Not set'
                        : MoneyFormatter.format(state.totalBudget!, cur),
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double? budget = state.budgetPerMonth;
    final double maxBar = state.maxMonthlyExpense;
    final double maxY =
        <double>[maxBar, budget ?? 0].reduce((a, b) => a > b ? a : b);
    final double topY = maxY <= 0 ? 1 : maxY * 1.2;
    final int lastIndex = state.months.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Monthly spending', style: textTheme.titleSmall),
                if (budget != null)
                  Text(
                    'Budget line',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: topY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  extraLinesData: budget == null
                      ? const ExtraLinesData()
                      : ExtraLinesData(
                          horizontalLines: <HorizontalLine>[
                            HorizontalLine(
                              y: budget,
                              color: scheme.error.withValues(alpha: 0.7),
                              strokeWidth: 1.5,
                              dashArray: <int>[6, 4],
                            ),
                          ],
                        ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (BarChartGroupData group, int groupIndex,
                          BarChartRodData rod, int rodIndex) {
                        return BarTooltipItem(
                          MoneyFormatter.format(rod.toY, state.currency),
                          textTheme.labelMedium!.copyWith(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int i = value.toInt();
                          if (i < 0 || i >= state.months.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.MMM().format(state.months[i].month),
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: <BarChartGroupData>[
                    for (int i = 0; i < state.months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: state.months[i].expense,
                            width: state.months.length > 8 ? 12 : 18,
                            color: _barColor(scheme, i, lastIndex, budget),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(ColorScheme scheme, int i, int lastIndex, double? budget) {
    final bool over = budget != null && state.months[i].expense > budget;
    if (over) return scheme.error;
    return i == lastIndex
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.35);
  }
}

class _BudgetCheckCard extends StatelessWidget {
  const _BudgetCheckCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (state.budgetPerMonth == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Set a monthly budget to see when you went over and why.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Most recent month first.
    final List<MonthBudgetCheck> checks = state.checks.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Budget check', style: textTheme.titleSmall),
                Text(
                  '${state.monthsOverBudget} of ${state.rangeMonths} over',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (int i = 0; i < checks.length; i++) ...<Widget>[
              if (i > 0) const Divider(height: 1),
              _CheckRow(check: checks[i], currency: state.currency),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check, required this.currency});

  final MonthBudgetCheck check;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool over = check.exceeded;
    final Color color = over ? scheme.error : const Color(0xFF16A34A);

    // "Why": the categories that drove the spend that month.
    final String drivers = check.drivers
        .map((CategorySpend d) =>
            '${d.name} ${MoneyFormatter.format(d.amount, currency)}')
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            over ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      DateFormatter.monthYear(check.month),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      over
                          ? 'Over by ${MoneyFormatter.format(check.over, currency)}'
                          : '${MoneyFormatter.format(check.remaining, currency)} left',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (drivers.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    over ? 'Driven by $drivers' : drivers,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double max = state.topCategories.first.amount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Top categories', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            for (final CategorySpend cs in state.topCategories) ...<Widget>[
              _CategoryBar(
                spend: cs,
                fraction: max <= 0 ? 0 : cs.amount / max,
                currency: state.currency,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.spend,
    required this.fraction,
    required this.currency,
  });

  final CategorySpend spend;
  final double fraction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color color = spend.category == null
        ? scheme.outline
        : Color(spend.category!.colorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                spend.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              MoneyFormatter.format(spend.amount, currency),
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.insights_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No data in this range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add a few transactions and your trends will show up here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
