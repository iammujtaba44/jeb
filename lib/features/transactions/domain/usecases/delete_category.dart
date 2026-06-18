import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class DeleteCategory extends UseCase<void, String> {
  const DeleteCategory(this._repository);

  final TransactionRepository _repository;

  @override
  ResultVoid call(String params) => _repository.deleteCategory(params);
}
