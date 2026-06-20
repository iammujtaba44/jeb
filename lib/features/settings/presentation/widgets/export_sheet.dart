import 'package:flutter/material.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/services/export_service.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/widgets/app_snackbar.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/search_transactions.dart';

/// Opens the export bottom sheet (choose a range, then CSV or PDF).
Future<void> showExportSheet(
  BuildContext context, {
  required String currency,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ExportSheet(currency: currency),
  );
}

enum _Range {
  thisMonth('This month', 'this-month'),
  last3('Last 3 months', 'last-3-months'),
  last6('Last 6 months', 'last-6-months'),
  thisYear('This year', 'this-year'),
  allTime('All time', 'all-time');

  const _Range(this.label, this.fileLabel);
  final String label;
  final String fileLabel;

  /// Inclusive start of the range, or null for "all time".
  DateTime? from(DateTime now) => switch (this) {
        _Range.thisMonth => DateTime(now.year, now.month),
        _Range.last3 => DateTime(now.year, now.month - 2),
        _Range.last6 => DateTime(now.year, now.month - 5),
        _Range.thisYear => DateTime(now.year),
        _Range.allTime => null,
      };
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.currency});

  final String currency;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  _Range _range = _Range.thisMonth;
  bool _busy = false;

  Future<void> _export({required bool pdf}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final NavigatorState navigator = Navigator.of(context);

    final DateTime now = DateTime.now();
    final SearchCriteria criteria =
        SearchCriteria(from: _range.from(now), to: now);

    final txResult = await getIt<SearchTransactions>()(criteria);
    final List<Transaction> transactions = txResult.fold(
      (_) => const <Transaction>[],
      (List<Transaction> t) => t,
    );

    if (transactions.isEmpty) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.show(context, 'No transactions in that range');
      return;
    }

    final catResult = await getIt<GetCategories>()(const NoParams());
    final Map<String, Category> categoriesById = catResult.fold(
      (_) => const <String, Category>{},
      (List<Category> c) => <String, Category>{for (final Category x in c) x.id: x},
    );

    final ExportService service = getIt<ExportService>();
    if (pdf) {
      await service.sharePdf(
        transactions: transactions,
        categoriesById: categoriesById,
        currency: widget.currency,
        label: _range.label,
      );
    } else {
      await service.shareCsv(
        transactions: transactions,
        categoriesById: categoriesById,
        label: _range.fileLabel,
      );
    }

    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Export transactions',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'RANGE',
              style: textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: <Widget>[
                for (final _Range r in _Range.values)
                  ChoiceChip(
                    selected: _range == r,
                    onSelected: _busy ? null : (_) => setState(() => _range = r),
                    label: Text(r.label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _export(pdf: false),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('CSV'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _export(pdf: true),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
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
