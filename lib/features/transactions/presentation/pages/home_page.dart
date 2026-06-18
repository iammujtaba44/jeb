import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:jeb/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:jeb/features/transactions/presentation/pages/search_page.dart';
import 'package:jeb/features/transactions/presentation/widgets/empty_transactions_view.dart';
import 'package:jeb/features/transactions/presentation/widgets/loading_view.dart';
import 'package:jeb/features/transactions/presentation/widgets/month_navigator.dart';
import 'package:jeb/features/transactions/presentation/widgets/month_summary_card.dart';
import 'package:jeb/features/transactions/presentation/widgets/spending_by_category.dart';
import 'package:jeb/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:jeb/features/transactions/presentation/widgets/transactions_error_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MonthNavigator(),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
            tooltip: 'Search',
            onPressed: () => _openSearch(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: const _HomeBody(),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final TransactionsCubit cubit = context.read<TransactionsCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SearchPage()),
    );
    await cubit.refresh();
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (BuildContext context, TransactionsState state) {
        return switch (state) {
          TransactionsInitial() || TransactionsLoading() => const LoadingView(),
          TransactionsError(:final String message) => TransactionsErrorView(
              message: message,
              onRetry: context.read<TransactionsCubit>().load,
            ),
          TransactionsLoaded() => RefreshIndicator(
              onRefresh: context.read<TransactionsCubit>().load,
              child: _LoadedContent(state: state),
            ),
        };
      },
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.state});

  final TransactionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final List<_Row> rows = _buildRows(state.transactions);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: MonthSummaryCard(
              income: state.totalIncome,
              expense: state.totalExpense,
              balance: state.balance,
              currencyCode: state.currencyCode,
              budgetLimit: state.overallBudget,
            ),
          ),
        ),
        if (state.totalExpense > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SpendingByCategory(
                transactions: state.transactions,
                categoriesById: state.categoriesById,
                currencyCode: state.currencyCode,
              ),
            ),
          ),
        if (state.transactions.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyTransactionsView(),
          )
        else
          SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) {
              final _Row row = rows[index];
              return switch (row) {
                _HeaderRow(:final String label) => _DayHeader(label: label),
                _TxnRow(:final Transaction transaction) => TransactionListItem(
                    transaction: transaction,
                    category: state.categoriesById[transaction.categoryId],
                    onTap: () => _openTransactionEditor(
                      context,
                      existing: transaction,
                      categories: state.categories,
                    ),
                    onDelete: (_) => _handleDelete(context, transaction),
                  ),
              };
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

/// A row in the grouped list: either a day header or a transaction.
sealed class _Row {
  const _Row();
}

final class _HeaderRow extends _Row {
  const _HeaderRow(this.label);
  final String label;
}

final class _TxnRow extends _Row {
  const _TxnRow(this.transaction);
  final Transaction transaction;
}

/// Groups date-sorted transactions under "Today" / "Yesterday" / date headers.
List<_Row> _buildRows(List<Transaction> transactions) {
  final List<_Row> rows = <_Row>[];
  String? currentLabel;
  for (final Transaction t in transactions) {
    final String label = _dayLabel(t.date);
    if (label != currentLabel) {
      currentLabel = label;
      rows.add(_HeaderRow(label));
    }
    rows.add(_TxnRow(t));
  }
  return rows;
}

String _dayLabel(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int diff = DateTime(now.year, now.month, now.day).difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormatter.dayMonth(date);
}

Future<void> _openTransactionEditor(
  BuildContext context, {
  Transaction? existing,
  required List<Category> categories,
}) async {
  HapticFeedback.selectionClick();
  final TransactionsCubit transactionsCubit = context.read<TransactionsCubit>();
  final String defaultCurrency =
      context.read<SettingsCubit>().state.settings.defaultCurrencyCode;
  final bool? saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => AddTransactionPage(
        categories: categories,
        transaction: existing,
        defaultCurrency: defaultCurrency,
      ),
    ),
  );
  if (saved ?? false) {
    await transactionsCubit.refresh();
  }
}

void _handleDelete(BuildContext context, Transaction transaction) {
  final TransactionsCubit cubit = context.read<TransactionsCubit>();
  HapticFeedback.mediumImpact();
  cubit.deleteTransaction(transaction.id);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => cubit.restore(transaction),
        ),
      ),
    );
}
