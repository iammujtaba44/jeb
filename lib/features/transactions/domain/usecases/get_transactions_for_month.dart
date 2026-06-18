import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class GetTransactionsForMonth
    extends UseCase<List<Transaction>, DateTime> {
  const GetTransactionsForMonth(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<List<Transaction>> call(DateTime params) {
    return _repository.getTransactionsForMonth(params);
  }
}
