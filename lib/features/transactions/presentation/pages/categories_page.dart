import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/presentation/cubit/categories_cubit.dart';
import 'package:jeb/features/transactions/presentation/pages/category_editor_page.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_avatar.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoriesCubit>(
      create: (_) => getIt<CategoriesCubit>()..load(),
      child: const CategoriesView(),
    );
  }
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New category',
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (BuildContext context, CategoriesState state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              const _SectionLabel('Expense'),
              _CategoryCard(categories: state.expenseCategories),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Income'),
              _CategoryCard(categories: state.incomeCategories),
              const SizedBox(height: 88),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Card(
        child: ListTile(title: Text('None yet — tap “New” to add one.')),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < categories.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, indent: 64),
            _CategoryTile(category: categories[i]),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CategoryAvatar(category: category, radius: 18),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: () => _confirmDelete(context, category),
      ),
      onTap: () => _openEditor(context, category),
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

Future<void> _openEditor(BuildContext context, Category? existing) async {
  final CategoriesCubit cubit = context.read<CategoriesCubit>();
  final Category? result = await Navigator.of(context).push<Category>(
    MaterialPageRoute<Category>(
      builder: (_) => CategoryEditorPage(existing: existing),
    ),
  );
  if (result != null) {
    await cubit.save(result);
  }
}

Future<void> _confirmDelete(BuildContext context, Category category) async {
  final CategoriesCubit cubit = context.read<CategoriesCubit>();
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Delete ${category.name}?'),
      content: const Text(
        'Existing transactions in this category will show as uncategorized.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    await cubit.delete(category.id);
  }
}
