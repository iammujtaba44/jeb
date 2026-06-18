import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';

/// Data-layer [Budget]. Stored keyed by category id, with the overall budget
/// stored under [DbConstants.overallBudgetKey].
final class BudgetModel extends Budget {
  const BudgetModel({
    required super.categoryId,
    required super.limitAmount,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final DateTime updatedAt;
  final bool isDeleted;

  factory BudgetModel.fromEntity(Budget budget, {required DateTime updatedAt}) {
    return BudgetModel(
      categoryId: budget.categoryId,
      limitAmount: budget.limitAmount,
      updatedAt: updatedAt,
    );
  }

  factory BudgetModel.fromMap(DataMap map) {
    final String id = map[DbConstants.columnId] as String;
    return BudgetModel(
      categoryId: id == DbConstants.overallBudgetKey ? null : id,
      limitAmount: (map[DbConstants.columnLimitAmount] as num).toDouble(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[DbConstants.columnUpdatedAt] as int,
      ),
      isDeleted: (map[DbConstants.columnIsDeleted] as int) == 1,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      DbConstants.columnId: categoryId ?? DbConstants.overallBudgetKey,
      DbConstants.columnLimitAmount: limitAmount,
      DbConstants.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
      DbConstants.columnIsDeleted: isDeleted ? 1 : 0,
    };
  }
}
