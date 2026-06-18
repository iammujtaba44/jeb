import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_colors.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/presentation/cubit/search_cubit.dart';
import 'package:jeb/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => getIt<SearchCubit>()..init(),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  hintText: 'Search notes…',
                ),
                onChanged: context.read<SearchCubit>().setQuery,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: const <Widget>[
          _FilterBar(),
          Divider(height: 1),
          Expanded(child: _Results()),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (SearchState p, SearchState c) => p.criteria != c.criteria,
      builder: (BuildContext context, SearchState state) {
        final SearchCubit cubit = context.read<SearchCubit>();
        final TransactionType? type = state.criteria.type;
        return SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: <Widget>[
              _Chip(
                label: 'Expense',
                selected: type == TransactionType.expense,
                onTap: () => cubit.setType(
                  type == TransactionType.expense ? null : TransactionType.expense,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'Income',
                selected: type == TransactionType.income,
                onTap: () => cubit.setType(
                  type == TransactionType.income ? null : TransactionType.income,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: _categoryLabel(state),
                selected: state.criteria.categoryId != null,
                onTap: () => _pickCategory(context, state),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: state.criteria.from == null
                    ? 'Date'
                    : '${DateFormatter.dayMonth(state.criteria.from!)} – ${DateFormatter.dayMonth(state.criteria.to!)}',
                selected: state.criteria.from != null,
                onTap: () => _pickDateRange(context, cubit),
              ),
              if (state.criteria.hasActiveFilters) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                ActionChip(
                  avatar: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                  onPressed: cubit.clearFilters,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _categoryLabel(SearchState state) {
    final String? id = state.criteria.categoryId;
    if (id == null) return 'Category';
    return state.categoriesById[id]?.name ?? 'Category';
  }

  Future<void> _pickCategory(BuildContext context, SearchState state) async {
    final SearchCubit cubit = context.read<SearchCubit>();
    final String? result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _CategoryFilterSheet(
        categories: state.categories,
        selected: state.criteria.categoryId,
      ),
    );
    if (result == null) return;
    cubit.setCategory(result.isEmpty ? null : result);
  }

  Future<void> _pickDateRange(BuildContext context, SearchCubit cubit) async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (range != null) {
      cubit.setDateRange(
        range.start,
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
      );
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (BuildContext context, SearchState state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.results.isEmpty) {
          return Center(
            child: Text(
              'No matching transactions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.separated(
          itemCount: state.results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final Transaction transaction = state.results[index];
            return _SearchResultTile(
              transaction: transaction,
              category: state.categoriesById[transaction.categoryId],
              onTap: () => _openEdit(context, transaction, state.categories),
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.transaction,
    required this.category,
    required this.onTap,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction.type == TransactionType.expense;
    final Color color = isExpense ? AppColors.expense : AppColors.income;
    final String sign = isExpense ? '-' : '+';
    final String subtitle = transaction.note?.isNotEmpty ?? false
        ? transaction.note!
        : DateFormatter.dayMonth(transaction.date);

    return ListTile(
      onTap: onTap,
      leading: category == null
          ? const Icon(Icons.help_outline)
          : CategoryAvatar(category: category!),
      title: Text(category?.name ?? 'Uncategorized'),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            '$sign${MoneyFormatter.format(transaction.amount, transaction.currencyCode)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormatter.dayMonth(transaction.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({required this.categories, required this.selected});

  final List<Category> categories;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ListTile(
            title: const Text('All categories'),
            trailing: selected == null
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(''),
          ),
          for (final Category c in categories)
            ListTile(
              leading: CategoryAvatar(category: c, radius: 16),
              title: Text(c.name),
              trailing: c.id == selected
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(c.id),
            ),
        ],
      ),
    );
  }
}

Future<void> _openEdit(
  BuildContext context,
  Transaction transaction,
  List<Category> categories,
) async {
  HapticFeedback.selectionClick();
  final SearchCubit cubit = context.read<SearchCubit>();
  final String currency =
      context.read<SettingsCubit>().state.settings.defaultCurrencyCode;
  final bool? saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => AddTransactionPage(
        categories: categories,
        transaction: transaction,
        defaultCurrency: currency,
      ),
    ),
  );
  if (saved ?? false) {
    await cubit.refresh();
  }
}
