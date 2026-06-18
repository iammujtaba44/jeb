import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class SaveCategory extends UseCase<void, Category> {
  const SaveCategory(this._repository);

  final TransactionRepository _repository;

  @override
  ResultVoid call(Category params) => _repository.saveCategory(params);
}
