import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/di/injection.dart';
import 'package:jeb/core/theme/app_spacing.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';
import 'package:jeb/features/transactions/presentation/widgets/amount_currency_field.dart';
import 'package:jeb/features/transactions/presentation/widgets/category_selector.dart';
import 'package:jeb/features/transactions/presentation/widgets/date_picker_tile.dart';
import 'package:jeb/features/transactions/presentation/widgets/note_input_field.dart';
import 'package:jeb/features/transactions/presentation/widgets/save_transaction_button.dart';
import 'package:jeb/features/transactions/presentation/widgets/transaction_type_selector.dart';

/// Add a new transaction, or edit an existing one when [transaction] is given.
class AddTransactionPage extends StatelessWidget {
  const AddTransactionPage({
    required this.categories,
    required this.defaultCurrency,
    this.transaction,
    super.key,
  });

  final List<Category> categories;
  final String defaultCurrency;
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddTransactionCubit>(
      create: (_) => getIt<AddTransactionCubit>()
        ..initialize(existing: transaction, defaultCurrency: defaultCurrency),
      child: AddTransactionView(
        categories: categories,
        isEditing: transaction != null,
        initialAmount: transaction?.amount,
        initialNote: transaction?.note,
      ),
    );
  }
}

class AddTransactionView extends StatelessWidget {
  const AddTransactionView({
    required this.categories,
    required this.isEditing,
    this.initialAmount,
    this.initialNote,
    super.key,
  });

  final List<Category> categories;
  final bool isEditing;
  final double? initialAmount;
  final String? initialNote;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddTransactionCubit, AddTransactionState>(
      listenWhen: (AddTransactionState prev, AddTransactionState curr) =>
          prev.status != curr.status,
      listener: _onStatusChanged,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            AmountCurrencyField(initialAmount: initialAmount),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(
              width: double.infinity,
              child: TransactionTypeSelector(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel(text: 'Category'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CategorySelector(categories: categories),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel(text: 'Details'),
            const SizedBox(height: AppSpacing.sm),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  const DatePickerTile(),
                  const Divider(height: 1, indent: 64),
                  NoteInputField(initialValue: initialNote),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SaveTransactionButton(),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _onStatusChanged(BuildContext context, AddTransactionState state) {
    switch (state.status) {
      case AddTransactionStatus.success:
        Navigator.of(context).pop(true);
      case AddTransactionStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? 'Could not save')),
        );
      case AddTransactionStatus.editing:
      case AddTransactionStatus.submitting:
        break;
    }
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
