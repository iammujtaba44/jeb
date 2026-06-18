import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/transactions/data/sync/sync_merge.dart';

class _Record {
  const _Record(this.id, this.updatedAt);
  final String id;
  final DateTime updatedAt;
}

List<_Record> _apply(List<_Record> local, List<_Record> remote) {
  return SyncMerge.recordsToApply<_Record>(
    local: local,
    remote: remote,
    idOf: (_Record r) => r.id,
    updatedAtOf: (_Record r) => r.updatedAt,
  );
}

void main() {
  final DateTime older = DateTime(2026, 6, 1);
  final DateTime newer = DateTime(2026, 6, 14);

  group('SyncMerge.recordsToApply (last-write-wins)', () {
    test('applies remote records missing locally', () {
      final result = _apply(const <_Record>[], <_Record>[_Record('a', older)]);
      expect(result.map((r) => r.id), <String>['a']);
    });

    test('applies remote when it is newer than local', () {
      final result = _apply(
        <_Record>[_Record('a', older)],
        <_Record>[_Record('a', newer)],
      );
      expect(result.single.updatedAt, newer);
    });

    test('does NOT apply remote when local is newer', () {
      final result = _apply(
        <_Record>[_Record('a', newer)],
        <_Record>[_Record('a', older)],
      );
      expect(result, isEmpty);
    });

    test('mixes: keeps newer local, takes newer remote, adds new remote', () {
      final result = _apply(
        <_Record>[_Record('a', newer), _Record('b', older)],
        <_Record>[_Record('a', older), _Record('b', newer), _Record('c', older)],
      );
      expect(result.map((r) => r.id).toSet(), <String>{'b', 'c'});
    });
  });
}
