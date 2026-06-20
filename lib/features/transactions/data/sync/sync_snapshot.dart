import 'dart:convert';

import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/plans/data/models/plan_model.dart';
import 'package:jeb/features/plans/data/models/plan_payment_model.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';

/// The serializable set of all local records exchanged during a sync.
class SyncSnapshot {
  const SyncSnapshot({
    required this.transactions,
    required this.categories,
    this.budgets = const <BudgetModel>[],
    this.recurring = const <RecurringTransactionModel>[],
    this.plans = const <PlanModel>[],
    this.planPayments = const <PlanPaymentModel>[],
    this.settings,
  });

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final List<BudgetModel> budgets;
  final List<RecurringTransactionModel> recurring;
  final List<PlanModel> plans;
  final List<PlanPaymentModel> planPayments;

  /// User preferences (excludes device-specific [AppSettings.lastSyncedAt]).
  final AppSettings? settings;

  static const int currentVersion = 4;
  static const String _versionKey = 'version';
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';
  static const String _budgetsKey = 'budgets';
  static const String _recurringKey = 'recurring';
  static const String _plansKey = 'plans';
  static const String _planPaymentsKey = 'planPayments';
  static const String _settingsKey = 'settings';

  factory SyncSnapshot.empty() => const SyncSnapshot(
        transactions: <TransactionModel>[],
        categories: <CategoryModel>[],
      );

  factory SyncSnapshot.fromJson(String source) {
    final Map<String, dynamic> map = jsonDecode(source) as Map<String, dynamic>;

    List<T> parse<T>(String key, T Function(DataMap) fromMap) =>
        (map[key] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic e) => fromMap(e as DataMap))
            .toList();

    return SyncSnapshot(
      transactions: parse(_transactionsKey, TransactionModel.fromMap),
      categories: parse(_categoriesKey, CategoryModel.fromMap),
      budgets: parse(_budgetsKey, BudgetModel.fromMap),
      recurring: parse(_recurringKey, RecurringTransactionModel.fromMap),
      plans: parse(_plansKey, PlanModel.fromMap),
      planPayments: parse(_planPaymentsKey, PlanPaymentModel.fromMap),
      settings: _settingsFromMap(map[_settingsKey] as DataMap?),
    );
  }

  String toJson() {
    return jsonEncode(<String, dynamic>{
      _versionKey: currentVersion,
      _transactionsKey:
          transactions.map((TransactionModel t) => t.toMap()).toList(),
      _categoriesKey: categories.map((CategoryModel c) => c.toMap()).toList(),
      _budgetsKey: budgets.map((BudgetModel b) => b.toMap()).toList(),
      _recurringKey:
          recurring.map((RecurringTransactionModel r) => r.toMap()).toList(),
      _plansKey: plans.map((PlanModel p) => p.toMap()).toList(),
      _planPaymentsKey:
          planPayments.map((PlanPaymentModel p) => p.toMap()).toList(),
      if (settings != null) _settingsKey: _settingsToMap(settings!),
    });
  }

  static DataMap _settingsToMap(AppSettings s) => <String, dynamic>{
        'currency': s.defaultCurrencyCode,
        'theme': s.themeMode.storageValue,
        'sync': s.syncEnabled,
        'appLock': s.appLockEnabled,
        'reminderEnabled': s.reminderEnabled,
        'reminderMinutes': s.reminderMinutes,
        'updatedAt': s.updatedAt?.millisecondsSinceEpoch,
      };

  static AppSettings? _settingsFromMap(DataMap? map) {
    if (map == null) return null;
    final int? updatedMs = map['updatedAt'] as int?;
    return AppSettings(
      defaultCurrencyCode:
          map['currency'] as String? ?? AppSettings.defaults.defaultCurrencyCode,
      themeMode: AppThemeMode.fromStorage(map['theme'] as String?),
      syncEnabled: map['sync'] as bool? ?? AppSettings.defaults.syncEnabled,
      appLockEnabled: map['appLock'] as bool? ?? false,
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      reminderMinutes: map['reminderMinutes'] as int? ??
          AppSettings.defaults.reminderMinutes,
      updatedAt:
          updatedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(updatedMs),
    );
  }
}
