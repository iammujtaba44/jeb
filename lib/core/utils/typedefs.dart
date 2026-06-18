import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/failures.dart';

/// A future that yields either a [Failure] or a value of type [T].
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// A future that yields either a [Failure] or nothing.
typedef ResultVoid = ResultFuture<void>;

/// Convenience alias for raw database / serialized rows.
typedef DataMap = Map<String, dynamic>;
