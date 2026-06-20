import 'package:equatable/equatable.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// A template that automatically generates transactions on a schedule.
/// [nextDueDate] is the next date an occurrence should be materialized; it is
/// advanced as occurrences are generated. [endDate] (inclusive) optionally
/// stops the series.
class RecurringTransaction extends Equatable {
  const RecurringTransaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.categoryId,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.endDate,
    this.note,
    this.accountId,
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String categoryId;
  final TransactionType type;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? endDate;
  final String? note;

  /// The account each generated occurrence is assigned to, or null.
  final String? accountId;

  RecurringTransaction copyWith({
    double? amount,
    String? currencyCode,
    String? categoryId,
    TransactionType? type,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    String? note,
    String? accountId,
  }) {
    return RecurringTransaction(
      id: id,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        amount,
        currencyCode,
        categoryId,
        type,
        frequency,
        startDate,
        nextDueDate,
        endDate,
        note,
        accountId,
      ];
}
