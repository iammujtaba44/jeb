import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/plans/data/models/plan_model.dart';
import 'package:jeb/features/plans/data/models/plan_payment_model.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class PlansLocalDataSource {
  Future<List<PlanModel>> getPlans();
  Future<void> upsertPlan(Plan plan);
  Future<void> deletePlan(String id);
  Future<Map<String, double>> paidByPlan();
  Future<List<PlanPaymentModel>> getPayments(String planId);
  Future<void> upsertPayment(PlanPayment payment);
  Future<void> deletePayment(String id);

  // Sync (include tombstones).
  Future<List<PlanModel>> getAllPlansForSync();
  Future<void> putPlan(PlanModel model);
  Future<List<PlanPaymentModel>> getAllPaymentsForSync();
  Future<void> putPayment(PlanPaymentModel model);
}

final class PlansLocalDataSourceImpl implements PlansLocalDataSource {
  const PlansLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<PlanModel>> getPlans() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.plansTable,
        where: '${DbConstants.columnIsDeleted} = 0',
        orderBy: '${DbConstants.columnDate} DESC',
      );
      return rows.map(PlanModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load plans: $error');
    }
  }

  @override
  Future<void> upsertPlan(Plan plan) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.plansTable,
        PlanModel.fromEntity(plan, updatedAt: DateTime.now()).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save plan: $error');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      final db = await _appDatabase.database;
      final int now = DateTime.now().millisecondsSinceEpoch;
      // Soft-delete the plan and its payments so removals propagate via sync.
      await db.update(
        DbConstants.plansTable,
        <String, dynamic>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
      await db.update(
        DbConstants.planPaymentsTable,
        <String, dynamic>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnPlanId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete plan: $error');
    }
  }

  @override
  Future<Map<String, double>> paidByPlan() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT ${DbConstants.columnPlanId} AS pid, '
        'SUM(${DbConstants.columnAmount}) AS total '
        'FROM ${DbConstants.planPaymentsTable} '
        'WHERE ${DbConstants.columnIsDeleted} = 0 '
        'GROUP BY ${DbConstants.columnPlanId}',
      );
      return <String, double>{
        for (final Map<String, Object?> r in rows)
          r['pid'] as String: (r['total'] as num?)?.toDouble() ?? 0,
      };
    } catch (error) {
      throw CacheException('Failed to total plan payments: $error');
    }
  }

  @override
  Future<List<PlanPaymentModel>> getPayments(String planId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.planPaymentsTable,
        where: '${DbConstants.columnPlanId} = ? AND '
            '${DbConstants.columnIsDeleted} = 0',
        whereArgs: <String>[planId],
        orderBy: '${DbConstants.columnDate} DESC',
      );
      return rows.map(PlanPaymentModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load payments: $error');
    }
  }

  @override
  Future<void> upsertPayment(PlanPayment payment) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.planPaymentsTable,
        PlanPaymentModel.fromEntity(payment, updatedAt: DateTime.now()).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save payment: $error');
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbConstants.planPaymentsTable,
        <String, dynamic>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete payment: $error');
    }
  }

  @override
  Future<List<PlanModel>> getAllPlansForSync() async {
    final db = await _appDatabase.database;
    final rows = await db.query(DbConstants.plansTable);
    return rows.map(PlanModel.fromMap).toList();
  }

  @override
  Future<void> putPlan(PlanModel model) async {
    final db = await _appDatabase.database;
    await db.insert(DbConstants.plansTable, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<PlanPaymentModel>> getAllPaymentsForSync() async {
    final db = await _appDatabase.database;
    final rows = await db.query(DbConstants.planPaymentsTable);
    return rows.map(PlanPaymentModel.fromMap).toList();
  }

  @override
  Future<void> putPayment(PlanPaymentModel model) async {
    final db = await _appDatabase.database;
    await db.insert(DbConstants.planPaymentsTable, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
