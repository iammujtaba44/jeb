import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/domain/repositories/recurring_repository.dart';

/// Materializes all recurring occurrences due on or before [DateTime] (usually
/// "now"). Returns the number of transactions generated.
final class MaterializeDueTransactions extends UseCase<int, DateTime> {
  const MaterializeDueTransactions(this._repository);

  final RecurringRepository _repository;

  @override
  ResultFuture<int> call(DateTime params) => _repository.materializeDue(params);
}
