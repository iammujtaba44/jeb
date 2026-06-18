import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class SyncData extends UseCase<void, NoParams> {
  const SyncData(this._repository);

  final TransactionRepository _repository;

  @override
  ResultVoid call(NoParams params) {
    return _repository.sync();
  }
}
