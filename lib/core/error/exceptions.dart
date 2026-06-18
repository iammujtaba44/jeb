/// Low-level exceptions thrown by data sources, mapped to [Failure]s
/// in the repository layer.
final class CacheException implements Exception {
  const CacheException(this.message);
  final String message;
}

final class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
}
