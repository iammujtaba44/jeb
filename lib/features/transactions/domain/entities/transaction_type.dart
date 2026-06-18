/// Whether a transaction is money out (expense) or in (income).
enum TransactionType {
  expense,
  income;

  String get storageValue => name;

  static TransactionType fromStorage(String value) {
    return TransactionType.values.firstWhere(
      (TransactionType type) => type.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}
