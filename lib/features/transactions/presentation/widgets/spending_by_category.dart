import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// One slice of the spending pie.
typedef _Slice = ({String name, Color color, double amount});

/// Pie chart + legend of the month's expenses by category, in the home currency.
class SpendingByCategory extends StatelessWidget {
  const SpendingByCategory({
    required this.transactions,
    required this.categoriesById,
    required this.currencyCode,
    super.key,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;
  final String currencyCode;

  static const int _maxSlices = 5;

  @override
  Widget build(BuildContext context) {
    final List<_Slice> slices = _buildSlices(context);
    if (slices.isEmpty) return const SizedBox.shrink();

    final double total =
        slices.fold(0, (double sum, _Slice s) => sum + s.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Spending by category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: slices
                            .map(
                              (_Slice s) => PieChartSectionData(
                                value: s.amount,
                                color: s.color,
                                radius: 26,
                                showTitle: false,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: slices
                          .map(
                            (_Slice s) => _LegendRow(
                              slice: s,
                              percent: total == 0 ? 0 : s.amount / total,
                              currencyCode: currencyCode,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Slice> _buildSlices(BuildContext context) {
    final Map<String, double> totals = <String, double>{};
    for (final Transaction t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final double converted = CurrencyConverter.convert(
        amount: t.amount,
        from: t.currencyCode,
        to: currencyCode,
      );
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + converted;
    }
    if (totals.isEmpty) return const <_Slice>[];

    final List<MapEntry<String, double>> ranked = totals.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));

    final List<_Slice> slices = <_Slice>[];
    for (final MapEntry<String, double> entry in ranked.take(_maxSlices)) {
      final Category? category = categoriesById[entry.key];
      slices.add((
        name: category?.name ?? 'Uncategorized',
        color: category == null
            ? Theme.of(context).colorScheme.outline
            : Color(category.colorValue),
        amount: entry.value,
      ));
    }

    if (ranked.length > _maxSlices) {
      final double otherTotal = ranked
          .skip(_maxSlices)
          .fold(0, (double sum, MapEntry<String, double> e) => sum + e.value);
      slices.add((
        name: 'Other',
        color: Theme.of(context).colorScheme.outlineVariant,
        amount: otherTotal,
      ));
    }
    return slices;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.percent,
    required this.currencyCode,
  });

  final _Slice slice;
  final double percent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              slice.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
