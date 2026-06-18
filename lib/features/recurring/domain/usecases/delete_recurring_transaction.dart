import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/domain/repositories/recurring_repository.dart';

final class DeleteRecurringTransaction extends UseCase<void, String> {
  const DeleteRecurringTransaction(this._repository);

  final RecurringRepository _repository;

  @override
  ResultVoid call(String params) =>
      _repository.deleteRecurringTransaction(params);
}
