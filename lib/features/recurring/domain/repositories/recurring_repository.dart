import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/domain/entities/recurring_transaction.dart';

abstract interface class RecurringRepository {
  ResultFuture<List<RecurringTransaction>> getRecurringTransactions();
  ResultVoid saveRecurringTransaction(RecurringTransaction rule);
  ResultVoid deleteRecurringTransaction(String id);

  /// Generates any transactions due on or before [asOf] from active rules and
  /// advances each rule's next-due date. Returns how many were created.
  ResultFuture<int> materializeDue(DateTime asOf);
}
