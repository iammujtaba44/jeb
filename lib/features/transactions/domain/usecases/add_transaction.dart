import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class AddTransaction extends UseCase<Transaction, Transaction> {
  const AddTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<Transaction> call(Transaction params) {
    return _repository.addTransaction(params);
  }
}
