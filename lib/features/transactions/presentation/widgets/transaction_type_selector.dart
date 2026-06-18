import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Expense / income toggle.
class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionType type = context.select<AddTransactionCubit, TransactionType>(
      (AddTransactionCubit cubit) => cubit.state.type,
    );

    return SegmentedButton<TransactionType>(
      segments: const <ButtonSegment<TransactionType>>[
        ButtonSegment<TransactionType>(
          value: TransactionType.expense,
          label: Text('Expense'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment<TransactionType>(
          value: TransactionType.income,
          label: Text('Income'),
          icon: Icon(Icons.arrow_downward),
        ),
      ],
      selected: <TransactionType>{type},
      onSelectionChanged: (Set<TransactionType> selection) =>
          context.read<AddTransactionCubit>().typeChanged(selection.first),
    );
  }
}
