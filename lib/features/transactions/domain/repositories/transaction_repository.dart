import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';

/// Contract the data layer fulfils. The presentation layer depends only on
/// this, never on a concrete implementation.
abstract interface class TransactionRepository {
  /// Transactions whose [Transaction.date] falls within the given [month].
  ResultFuture<List<Transaction>> getTransactionsForMonth(DateTime month);

  /// Searches all transactions matching the given [criteria].
  ResultFuture<List<Transaction>> searchTransactions(SearchCriteria criteria);

  ResultFuture<Transaction> addTransaction(Transaction transaction);

  ResultVoid deleteTransaction(String id);

  ResultFuture<List<Category>> getCategories();
  ResultVoid saveCategory(Category category);
  ResultVoid deleteCategory(String id);

  /// Pushes local changes to and pulls remote changes from the user's cloud.
  ResultVoid sync();
}
