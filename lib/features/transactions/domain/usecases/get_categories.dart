import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

final class GetCategories extends UseCase<List<Category>, NoParams> {
  const GetCategories(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<List<Category>> call(NoParams params) {
    return _repository.getCategories();
  }
}
