import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class DeleteTransaction extends UseCase<void, String> {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  ResultVoid call(String params) {
    return _repository.deleteTransaction(params);
  }
}
