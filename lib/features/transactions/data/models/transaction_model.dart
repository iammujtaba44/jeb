import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

/// Data-layer representation of a [Transaction] plus sync metadata
/// (`updatedAt` and a soft-delete tombstone) used for cloud merging.
final class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.currencyCode,
    required super.categoryId,
    required super.date,
    required super.type,
    required this.updatedAt,
    this.isDeleted = false,
    super.note,
    super.recurringId,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory TransactionModel.fromEntity(
    Transaction entity, {
    required DateTime updatedAt,
    bool isDeleted = false,
  }) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      currencyCode: entity.currencyCode,
      categoryId: entity.categoryId,
      date: entity.date,
      type: entity.type,
      note: entity.note,
      recurringId: entity.recurringId,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  factory TransactionModel.fromMap(DataMap map) {
    return TransactionModel(
      id: map[DbConstants.columnId] as String,
      amount: (map[DbConstants.columnAmount] as num).toDouble(),
      currencyCode: map[DbConstants.columnCurrencyCode] as String,
      categoryId: map[DbConstants.columnCategoryId] as String,
      date: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnDate] as int,
      ),
      type: TransactionType.fromStorage(map[DbConstants.columnType] as String),
      note: map[DbConstants.columnNote] as String?,
      recurringId: map[DbConstants.columnRecurringId] as String?,
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
      DbConstants.columnDate: date.millisecondsSinceEpoch,
      DbConstants.columnType: type.storageValue,
      DbConstants.columnNote: note,
      DbConstants.columnRecurringId: recurringId,
      DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
      DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
    };
  }

  @override
  List<Object?> get props => [...super.props, updatedAt, isDeleted];
}
