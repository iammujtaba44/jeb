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
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String categoryId;
  final DateTime date;
  final TransactionType type;
  final String? note;

  @override
  List<Object?> get props => [
        id,
        amount,
        currencyCode,
        categoryId,
        date,
        type,
        note,
      ];
}
