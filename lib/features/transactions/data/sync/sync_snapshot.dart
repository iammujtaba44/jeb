import 'dart:convert';

import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';

/// The serializable set of all local records exchanged during a sync.
class SyncSnapshot {
  const SyncSnapshot({
    required this.transactions,
    required this.categories,
    this.budgets = const <BudgetModel>[],
    this.recurring = const <RecurringTransactionModel>[],
  });

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final List<BudgetModel> budgets;
  final List<RecurringTransactionModel> recurring;

  static const int currentVersion = 2;
  static const String _versionKey = 'version';
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';
  static const String _budgetsKey = 'budgets';
  static const String _recurringKey = 'recurring';

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
    });
  }
}
