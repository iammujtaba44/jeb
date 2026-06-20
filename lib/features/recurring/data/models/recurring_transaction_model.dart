import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:jeb/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// Data-layer [RecurringTransaction] with persistence metadata.
final class RecurringTransactionModel extends RecurringTransaction {
  const RecurringTransactionModel({
    required super.id,
    required super.amount,
    required super.currencyCode,
    required super.categoryId,
    required super.type,
    required super.frequency,
    required super.startDate,
    required super.nextDueDate,
    required this.updatedAt,
    super.endDate,
    super.note,
    super.accountId,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory RecurringTransactionModel.fromEntity(
    RecurringTransaction rule, {
    required DateTime updatedAt,
  }) {
    return RecurringTransactionModel(
      id: rule.id,
      amount: rule.amount,
      currencyCode: rule.currencyCode,
      categoryId: rule.categoryId,
      type: rule.type,
      frequency: rule.frequency,
      startDate: rule.startDate,
      nextDueDate: rule.nextDueDate,
      endDate: rule.endDate,
      note: rule.note,
      accountId: rule.accountId,
      updatedAt: updatedAt,
    );
  }

  factory RecurringTransactionModel.fromMap(DataMap map) {
    final int? endMs = map[DbConstants.columnEndDate] as int?;
    return RecurringTransactionModel(
      id: map[DbConstants.columnId] as String,
      amount: (map[DbConstants.columnAmount] as num).toDouble(),
      currencyCode: map[DbConstants.columnCurrencyCode] as String,
      categoryId: map[DbConstants.columnCategoryId] as String,
      type: TransactionType.fromStorage(map[DbConstants.columnType] as String),
      frequency: RecurrenceFrequency.fromStorage(
        map[DbConstants.columnFrequency] as String,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnStartDate] as int,
      ),
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnNextDueDate] as int,
      ),
      endDate:
          endMs == null ? null : DateTime.fromMillisecondsSinceEpoch(endMs),
      note: map[DbConstants.columnNote] as String?,
      accountId: map[DbConstants.columnAccountId] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      DbConstants.columnId: id,
      DbConstants.columnAmount: amount,
      DbConstants.columnCurrencyCode: currencyCode,
      DbConstants.columnCategoryId: categoryId,
      DbConstants.columnNote: note,
      DbConstants.columnType: type.storageValue,
      DbConstants.columnFrequency: frequency.storageValue,
      DbConstants.columnStartDate: startDate.millisecondsSinceEpoch,
      DbConstants.columnNextDueDate: nextDueDate.millisecondsSinceEpoch,
      DbConstants.columnEndDate: endDate?.millisecondsSinceEpoch,
      DbConstants.columnAccountId: accountId,
      DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
      DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
    };
  }
}
