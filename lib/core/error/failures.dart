import 'package:equatable/equatable.dart';

/// Base type for all recoverable, user-facing failures (domain layer).
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
