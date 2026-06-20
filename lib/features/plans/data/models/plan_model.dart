import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';

final class PlanModel extends Plan {
  const PlanModel({
    required super.id,
    required super.name,
    required super.kind,
    required super.currencyCode,
    required super.startDate,
    required this.updatedAt,
    super.targetAmount,
    super.installmentAmount,
    super.note,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory PlanModel.fromEntity(Plan p, {required DateTime updatedAt}) {
    return PlanModel(
      id: p.id,
      name: p.name,
      kind: p.kind,
      currencyCode: p.currencyCode,
      startDate: p.startDate,
      targetAmount: p.targetAmount,
      installmentAmount: p.installmentAmount,
      note: p.note,
      updatedAt: updatedAt,
    );
  }

  factory PlanModel.fromMap(DataMap map) {
    return PlanModel(
      id: map[DbConstants.columnId] as String,
      name: map[DbConstants.columnName] as String,
      kind: PlanKind.fromStorage(map[DbConstants.columnKind] as String),
      currencyCode: map[DbConstants.columnCurrencyCode] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnDate] as int,
      ),
      targetAmount: (map[DbConstants.columnTargetAmount] as num?)?.toDouble(),
      installmentAmount:
          (map[DbConstants.columnInstallmentAmount] as num?)?.toDouble(),
      note: map[DbConstants.columnNote] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() => <String, dynamic>{
        DbConstants.columnId: id,
        DbConstants.columnName: name,
        DbConstants.columnKind: kind.storageValue,
        DbConstants.columnTargetAmount: targetAmount,
        DbConstants.columnInstallmentAmount: installmentAmount,
        DbConstants.columnCurrencyCode: currencyCode,
        DbConstants.columnNote: note,
        DbConstants.columnDate: startDate.millisecondsSinceEpoch,
        DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
        DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
      };
}
