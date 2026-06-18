import 'package:equatable/equatable.dart';
import 'package:jeb/core/utils/typedefs.dart';

/// Base contract for a use case that takes [Params] and returns [Type].
abstract class UseCase<ResultType, Params> {
  const UseCase();

  ResultFuture<ResultType> call(Params params);
}

/// Marker for use cases that take no parameters.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
