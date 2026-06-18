import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_colors.dart';
import 'package:jeb/core/utils/formatters.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_avatar.dart';

/// A single row in the transaction list. Swipe to delete.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.transaction,
    required this.category,
    required this.onDelete,
    this.onTap,
    super.key,
  });

  final Transaction transaction;
  final Category? category;
  final ValueChanged<String> onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isExpense = transaction.type == TransactionType.expense;
    final Color amountColor = isExpense ? AppColors.expense : AppColors.income;
    final String sign = isExpense ? '-' : '+';
    final String subtitle = transaction.note?.isNotEmpty ?? false
        ? transaction.note!
        : DateFormatter.dayMonth(transaction.date);

    return Dismissible(
      key: ValueKey<String>(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(transaction.id),
      background: const _DeleteBackground(),
      child: ListTile(
        onTap: onTap,
        leading: category == null
            ? const Icon(Icons.help_outline)
            : CategoryAvatar(category: category!),
        title: Text(category?.name ?? 'Uncategorized'),
        subtitle: Text(subtitle),
        trailing: Text(
          '$sign${MoneyFormatter.format(transaction.amount, transaction.currencyCode)}',
          style: textTheme.titleMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.expense,
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Icon(Icons.delete_outline, color: Colors.white),
        ),
      ),
    );
  }
}
