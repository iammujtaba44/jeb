import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class SearchTransactions
    extends UseCase<List<Transaction>, SearchCriteria> {
  const SearchTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<List<Transaction>> call(SearchCriteria params) =>
      _repository.searchTransactions(params);
}
