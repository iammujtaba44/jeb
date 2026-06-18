/// Pure last-write-wins merge logic, isolated so it can be unit-tested without
/// a database or network.
abstract final class SyncMerge {
  const SyncMerge._();

  /// Returns the remote records that should replace the local copy — i.e. the
  /// local record is missing or strictly older than the remote one. Deletes
  /// are handled naturally because tombstones carry an [updatedAtOf] too.
  static List<T> recordsToApply<T>({
    required List<T> local,
    required List<T> remote,
    required String Function(T item) idOf,
    required DateTime Function(T item) updatedAtOf,
  }) {
    final Map<String, T> localById = <String, T>{
      for (final T item in local) idOf(item): item,
    };

    final List<T> toApply = <T>[];
    for (final T remoteItem in remote) {
      final T? localItem = localById[idOf(remoteItem)];
      final bool localIsOlder = localItem == null ||
          updatedAtOf(localItem).isBefore(updatedAtOf(remoteItem));
      if (localIsOlder) {
        toApply.add(remoteItem);
      }
    }
    return toApply;
  }
}
