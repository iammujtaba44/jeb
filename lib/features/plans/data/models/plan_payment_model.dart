import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';

final class PlanPaymentModel extends PlanPayment {
  const PlanPaymentModel({
    required super.id,
    required super.planId,
    required super.amount,
    required super.date,
    required this.updatedAt,
    super.note,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory PlanPaymentModel.fromEntity(
    PlanPayment p, {
    required DateTime updatedAt,
  }) {
    return PlanPaymentModel(
      id: p.id,
      planId: p.planId,
      amount: p.amount,
      date: p.date,
      note: p.note,
      updatedAt: updatedAt,
    );
  }

  factory PlanPaymentModel.fromMap(DataMap map) {
    return PlanPaymentModel(
      id: map[DbConstants.columnId] as String,
      planId: map[DbConstants.columnPlanId] as String,
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
        DbConstants.columnPlanId: planId,
        DbConstants.columnAmount: amount,
        DbConstants.columnDate: date.millisecondsSinceEpoch,
        DbConstants.columnNote: note,
        DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
        DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
      };
}
