import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';

final class TransferModel extends Transfer {
  const TransferModel({
    required super.id,
    required super.fromAccountId,
    required super.toAccountId,
    required super.amount,
    required super.date,
    required this.updatedAt,
    super.note,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory TransferModel.fromEntity(Transfer t, {required DateTime updatedAt}) {
    return TransferModel(
      id: t.id,
      fromAccountId: t.fromAccountId,
      toAccountId: t.toAccountId,
      amount: t.amount,
      date: t.date,
      note: t.note,
      updatedAt: updatedAt,
    );
  }

  factory TransferModel.fromMap(DataMap map) {
    return TransferModel(
      id: map[DbConstants.columnId] as String,
      fromAccountId: map[DbConstants.columnFromAccountId] as String,
      toAccountId: map[DbConstants.columnToAccountId] as String,
      amount: (map[DbConstants.columnAmount] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnDate] as int,
      ),
      note: map[DbConstants.columnNote] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() => <String, dynamic>{
        DbConstants.columnId: id,
        DbConstants.columnFromAccountId: fromAccountId,
        DbConstants.columnToAccountId: toAccountId,
        DbConstants.columnAmount: amount,
        DbConstants.columnDate: date.millisecondsSinceEpoch,
        DbConstants.columnNote: note,
        DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
        DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
      };
}
