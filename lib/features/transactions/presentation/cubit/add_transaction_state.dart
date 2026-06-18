part of 'add_transaction_cubit.dart';

enum AddTransactionStatus { editing, submitting, success, failure }

final class AddTransactionState extends Equatable {
  const AddTransactionState({
    required this.date,
    this.amount = 0,
    this.type = TransactionType.expense,
    this.selectedCategoryId,
    this.note = '',
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.editingId,
    this.status = AddTransactionStatus.editing,
    this.errorMessage,
  });

  final double amount;
  final TransactionType type;
  final String? selectedCategoryId;
  final String note;
  final String currencyCode;
  final String? editingId;
  final DateTime date;
  final AddTransactionStatus status;
  final String? errorMessage;

  bool get isEditing => editingId != null;
  bool get canSubmit => amount > 0 && selectedCategoryId != null;
  bool get isSubmitting => status == AddTransactionStatus.submitting;

  AddTransactionState copyWith({
    double? amount,
    TransactionType? type,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? note,
    String? currencyCode,
    DateTime? date,
    AddTransactionStatus? status,
    String? errorMessage,
  }) {
    return AddTransactionState(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      note: note ?? this.note,
      currencyCode: currencyCode ?? this.currencyCode,
      editingId: editingId,
      date: date ?? this.date,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        amount,
        type,
        selectedCategoryId,
        note,
        currencyCode,
        editingId,
        date,
        status,
        errorMessage,
      ];
}
