import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/app_snackbar.dart';
import 'package:jeb/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:jeb/features/accounts/presentation/widgets/accounts_carousel.dart';
import 'package:jeb/features/insights/presentation/pages/insights_page.dart';
import 'package:jeb/features/plans/presentation/cubit/plans_cubit.dart';
import 'package:jeb/features/plans/presentation/widgets/plans_carousel.dart';
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
            icon: Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.bold)),
            tooltip: 'Insights',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
            ),
          ),
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
}

/// Reloads the dashboard's three data sources together (pull-to-refresh).
Future<void> _refreshAll(BuildContext context) async {
  final TransactionsCubit transactions = context.read<TransactionsCubit>();
  final AccountsCubit accounts = context.read<AccountsCubit>();
  final PlansCubit plans = context.read<PlansCubit>();
  await Future.wait(<Future<void>>[
    transactions.load(),
    accounts.load(),
    plans.load(),
  ]);
}

Future<void> _openSearch(BuildContext context) async {
  final TransactionsCubit cubit = context.read<TransactionsCubit>();
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const SearchPage()),
  );
  await cubit.refresh();
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
              onRefresh: () => _refreshAll(context),
              child: _LoadedContent(state: state),
            ),
        };
      },
    );
  }
}

/// How many transactions the home screen shows before "View all".
const int _recentLimit = 5;

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.state});

  final TransactionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final List<Transaction> recent =
        state.transactions.take(_recentLimit).toList();

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
        const SliverToBoxAdapter(child: AccountsCarousel()),
        const SliverToBoxAdapter(child: PlansCarousel()),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyTransactionsView(),
            ),
          )
        else ...<Widget>[
          SliverToBoxAdapter(
            child: _RecentHeader(
              hasMore: state.transactions.length > _recentLimit,
              onViewAll: () => _openSearch(context),
            ),
          ),
          SliverList.builder(
            itemCount: recent.length,
            itemBuilder: (BuildContext context, int index) {
              final Transaction transaction = recent[index];
              return TransactionListItem(
                transaction: transaction,
                category: state.categoriesById[transaction.categoryId],
                onTap: () => _openTransactionEditor(
                  context,
                  existing: transaction,
                  categories: state.categories,
                ),
                onDelete: (_) => _handleDelete(context, transaction),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

/// Header above the recent-transactions list with a "View all" affordance.
class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.hasMore, required this.onViewAll});

  final bool hasMore;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Recent',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          if (hasMore)
            TextButton(
              onPressed: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('View all'),
                  const SizedBox(width: 2),
                  Icon(PhosphorIcons.caretRight(), size: 14, color: scheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

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
  AppSnackbar.show(
    context,
    'Transaction deleted',
    actionLabel: 'Undo',
    onAction: () => cubit.restore(transaction),
  );
}
