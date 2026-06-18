import 'dart:convert';

import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';

/// The serializable set of all local records exchanged during a sync.
class SyncSnapshot {
  const SyncSnapshot({required this.transactions, required this.categories});

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  static const int currentVersion = 1;
  static const String _versionKey = 'version';
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';

  factory SyncSnapshot.empty() =>
      const SyncSnapshot(transactions: <TransactionModel>[], categories: <CategoryModel>[]);

  factory SyncSnapshot.fromJson(String source) {
    final Map<String, dynamic> map = jsonDecode(source) as Map<String, dynamic>;
    final List<dynamic> rawTransactions =
        map[_transactionsKey] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawCategories =
        map[_categoriesKey] as List<dynamic>? ?? const <dynamic>[];

    return SyncSnapshot(
      transactions: rawTransactions
          .map((dynamic e) => TransactionModel.fromMap(e as DataMap))
          .toList(),
      categories: rawCategories
          .map((dynamic e) => CategoryModel.fromMap(e as DataMap))
          .toList(),
    );
  }

  String toJson() {
    return jsonEncode(<String, dynamic>{
      _versionKey: currentVersion,
      _transactionsKey:
          transactions.map((TransactionModel t) => t.toMap()).toList(),
      _categoriesKey: categories.map((CategoryModel c) => c.toMap()).toList(),
    });
  }
}
