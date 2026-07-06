import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/widgets/app_snackbar.dart';
import 'package:jeb/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:jeb/features/accounts/presentation/widgets/accounts_carousel.dart';
import 'package:jeb/features/home/domain/home_section.dart';
import 'package:jeb/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:jeb/features/home/presentation/pages/customize_home_page.dart';
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
        centerTitle: false,
        titleSpacing: AppSpacing.sm,
        toolbarHeight: 64,
        title: const MonthNavigator(),
        actions: <Widget>[
          _AppBarAction(
            icon: PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
            tooltip: 'Insights',
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
            ),
          ),
          _AppBarAction(
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            tooltip: 'Search',
            onTap: () => _openSearch(context),
          ),
          _AppBarAction(
            icon: PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold),
            tooltip: 'Customize home',
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const CustomizeHomePage()),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: const _HomeBody(),
    );
  }
}

/// A soft, circular app-bar button that echoes the month pill's surface tint —
/// keeps the top bar reading as one cohesive set of controls.
class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          foregroundColor: scheme.onSurface,
          shape: const CircleBorder(),
          minimumSize: const Size(42, 42),
          padding: EdgeInsets.zero,
        ),
      ),
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

/// [autofocus] raises the keyboard immediately — true for the search icon
/// (you came to search), false for "View all" (you came to browse).
Future<void> _openSearch(BuildContext context, {bool autofocus = true}) async {
  final TransactionsCubit cubit = context.read<TransactionsCubit>();
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => SearchPage(autofocus: autofocus)),
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
              child: _MonthSwipe(
                month: state.month,
                child: _LoadedContent(state: state),
              ),
            ),
        };
      },
    );
  }
}

/// Horizontal swipe anywhere on the dashboard steps between months (left =
/// forward, right = back), with a directional slide as the new month loads.
class _MonthSwipe extends StatefulWidget {
  const _MonthSwipe({required this.month, required this.child});

  final DateTime month;
  final Widget child;

  @override
  State<_MonthSwipe> createState() => _MonthSwipeState();
}

class _MonthSwipeState extends State<_MonthSwipe> {
  static const double _minFlingVelocity = 250;

  /// +1 when moving forward in time, -1 when moving back — drives the slide.
  int _direction = 0;
  late DateTime _lastMonth = widget.month;

  @override
  void didUpdateWidget(_MonthSwipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.month != _lastMonth) {
      _direction = widget.month.isAfter(_lastMonth) ? 1 : -1;
      _lastMonth = widget.month;
    }
  }

  void _onDragEnd(BuildContext context, DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _minFlingVelocity) return;
    final TransactionsCubit cubit = context.read<TransactionsCubit>();
    HapticFeedback.selectionClick();
    if (velocity < 0) {
      cubit.goToNextMonth(); // swipe left → forward (no-op on current month)
    } else {
      cubit.goToPreviousMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (DragEndDetails d) => _onDragEnd(context, d),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // The incoming month slides in from the side it was swiped toward;
          // the first build (direction 0) just fades.
          final Offset begin = Offset(0.12 * _direction, 0);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: begin, end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
          fit: StackFit.expand,
          children: <Widget>[...previous, if (current != null) current],
        ),
        child: KeyedSubtree(
          key: ValueKey<DateTime>(widget.month),
          child: widget.child,
        ),
      ),
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
    return BlocBuilder<HomeLayoutCubit, HomeLayout>(
      builder: (BuildContext context, HomeLayout layout) {
        final List<HomeSection> visible = layout.visible;
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (visible.isEmpty)
              const SliverToBoxAdapter(child: _EmptyHome())
            else
              for (final HomeSection section in visible)
                ..._sectionSlivers(context, section),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }

  /// The slivers for one [HomeSection]. Some sections render nothing when they
  /// have no data to show (e.g. spending with no expense).
  List<Widget> _sectionSlivers(BuildContext context, HomeSection section) {
    switch (section) {
      case HomeSection.summary:
        return <Widget>[
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
        ];
      case HomeSection.accounts:
        return const <Widget>[SliverToBoxAdapter(child: AccountsCarousel())];
      case HomeSection.plans:
        return const <Widget>[SliverToBoxAdapter(child: PlansCarousel())];
      case HomeSection.spending:
        if (state.totalExpense <= 0) return const <Widget>[];
        return <Widget>[
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
        ];
      case HomeSection.recent:
        if (state.transactions.isEmpty) {
          return const <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyTransactionsView(),
              ),
            ),
          ];
        }
        final List<Transaction> recent =
            state.transactions.take(_recentLimit).toList();
        return <Widget>[
          SliverToBoxAdapter(
            child: _RecentHeader(
              hasMore: state.transactions.length > _recentLimit,
              onViewAll: () => _openSearch(context, autofocus: false),
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
        ];
    }
  }
}

/// Shown when every home section has been switched off.
class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          Icon(PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.duotone),
              size: 52, color: scheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your home is empty',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the sliders icon to turn sections back on.',
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
