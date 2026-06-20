import 'package:equatable/equatable.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// A single money movement. Sync metadata (updatedAt / tombstone) lives in the
/// data-layer model, keeping this domain entity focused on what the app means.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.categoryId,
    required this.date,
    required this.type,
    this.note,
    this.recurringId,
    this.receiptPath,
    this.accountId,
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String categoryId;
  final DateTime date;
  final TransactionType type;
  final String? note;

  /// The id of the recurring rule that generated this transaction, or null for
  /// a one-off transaction.
  final String? recurringId;

  /// Relative path of an attached receipt photo (within the documents dir),
  /// or null if none.
  final String? receiptPath;

  /// The wallet/account this transaction draws from or lands in, or null when
  /// it isn't tied to a specific account.
  final String? accountId;

  bool get isRecurring => recurringId != null;
  bool get hasReceipt => receiptPath != null;

  @override
  List<Object?> get props => [
        id,
        amount,
        currencyCode,
        categoryId,
        date,
        type,
        note,
        recurringId,
        receiptPath,
        accountId,
      ];
}
