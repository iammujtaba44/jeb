import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:jeb/features/recurring/domain/repositories/recurring_repository.dart';

final class SaveRecurringTransaction
    extends UseCase<void, RecurringTransaction> {
  const SaveRecurringTransaction(this._repository);

  final RecurringRepository _repository;

  @override
  ResultVoid call(RecurringTransaction params) =>
      _repository.saveRecurringTransaction(params);
}
