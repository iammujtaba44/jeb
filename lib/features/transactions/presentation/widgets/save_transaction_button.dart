import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

/// Submit button — enabled only when the form is valid, shows progress while
/// submitting.
class SaveTransactionButton extends StatelessWidget {
  const SaveTransactionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddTransactionCubit, AddTransactionState>(
      buildWhen: (AddTransactionState prev, AddTransactionState curr) =>
          prev.canSubmit != curr.canSubmit ||
          prev.isSubmitting != curr.isSubmitting,
      builder: (BuildContext context, AddTransactionState state) {
        return FilledButton(
          onPressed: state.canSubmit && !state.isSubmitting
              ? context.read<AddTransactionCubit>().submit
              : null,
          child: state.isSubmitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(state.isEditing ? 'Update' : 'Save'),
        );
      },
    );
  }
}
