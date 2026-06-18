import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/presentation/widgets/transaction_list_item.dart';

/// Scrollable list of the month's transactions.
class TransactionList extends StatelessWidget {
  const TransactionList({
    required this.transactions,
    required this.categoriesById,
    required this.onDelete,
    super.key,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoriesById;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Transaction transaction = transactions[index];
        return TransactionListItem(
          transaction: transaction,
          category: categoriesById[transaction.categoryId],
          onDelete: onDelete,
        );
      },
    );
  }
}
