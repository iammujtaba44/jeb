import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Chips for choosing a category, filtered to the currently selected type.
class CategorySelector extends StatelessWidget {
  const CategorySelector({required this.categories, super.key});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState prev, AddTransactionState curr) =>
          prev.type != curr.type ||
          prev.selectedCategoryId != curr.selectedCategoryId,
      builder: (BuildContext context, AddTransactionState state) {
        final List<Category> visible = categories
            .where((Category c) => c.type == state.type)
            .toList(growable: false);

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: visible
              .map(
                (Category category) => _CategoryChip(
                  category: category,
                  selected: category.id == state.selectedCategoryId,
                  onSelected: () => context
                      .read<AddTransactionCubit>()
                      .categorySelected(category.id),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final Category category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(category.colorValue);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
        color: color,
        size: 18,
      ),
      label: Text(category.name),
    );
  }
}
