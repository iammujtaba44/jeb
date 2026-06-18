import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/add_transaction.dart';
import 'package:uuid/uuid.dart';

part 'add_transaction_state.dart';

/// Holds the add/edit form state and saves the [Transaction]. Reused for both
/// creating a new transaction and editing an existing one.
class AddTransactionCubit extends Cubit<AddTransactionState> {
  AddTransactionCubit({
    required AddTransaction addTransaction,
    required Uuid uuid,
  })  : _addTransaction = addTransaction,
        _uuid = uuid,
        super(AddTransactionState(date: DateTime.now()));

  final AddTransaction _addTransaction;
  final Uuid _uuid;

  /// Seed the form — either blank (with the user's default currency) or
  /// pre-filled from an [existing] transaction for editing.
  void initialize({Transaction? existing, required String defaultCurrency}) {
    if (existing == null) {
      emit(AddTransactionState(date: DateTime.now(), currencyCode: defaultCurrency));
      return;
    }
    emit(
      AddTransactionState(
        date: existing.date,
        amount: existing.amount,
        type: existing.type,
        selectedCategoryId: existing.categoryId,
        note: existing.note ?? '',
        currencyCode: existing.currencyCode,
        editingId: existing.id,
      ),
    );
  }

  void amountChanged(double amount) =>
      emit(state.copyWith(amount: amount, status: AddTransactionStatus.editing));

  void typeChanged(TransactionType type) =>
      emit(state.copyWith(type: type, clearCategory: true));

  void categorySelected(String categoryId) =>
      emit(state.copyWith(selectedCategoryId: categoryId));

  void currencyChanged(String currencyCode) =>
      emit(state.copyWith(currencyCode: currencyCode));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  Future<void> submit() async {
    if (!state.canSubmit || state.isSubmitting) return;

    emit(state.copyWith(status: AddTransactionStatus.submitting));

    final Transaction transaction = Transaction(
      id: state.editingId ?? _uuid.v4(),
      amount: state.amount,
      currencyCode: state.currencyCode,
      categoryId: state.selectedCategoryId!,
      date: state.date,
      type: state.type,
      note: state.note.trim().isEmpty ? null : state.note.trim(),
    );

    final result = await _addTransaction(transaction);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AddTransactionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: AddTransactionStatus.success)),
    );
  }
}
