import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/sync/conflict_resolver.dart';
import 'package:musheet/rpc/rpc_protocol.dart';

void main() {
  group('ConflictDetector', () {
    test('no conflict when versions match', () {
      final result = ConflictDetector.detectConflict(
        localData: {'title': 'Same'},
        serverData: {'title': 'Same'},
        localVersion: 1,
        serverVersion: 1,
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        entityType: SyncEntityType.score,
      );

      expect(result.hasConflict, isFalse);
    });

    test('no conflict when server is ahead and local is empty', () {
      final result = ConflictDetector.detectConflict(
        localData: {},
        serverData: {'title': 'Server Title'},
        localVersion: 1,
        serverVersion: 2,
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        entityType: SyncEntityType.score,
      );

      expect(result.hasConflict, isFalse);
    });

    test('conflict when both have changes', () {
      final result = ConflictDetector.detectConflict(
        localData: {'title': 'Local Title'},
        serverData: {'title': 'Server Title'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime(2024, 1, 15),
        serverUpdatedAt: DateTime(2024, 1, 16),
        entityType: SyncEntityType.score,
      );

      expect(result.hasConflict, isTrue);
      expect(result.conflictType, ConflictType.dataConflict);
    });

    test('detects delete conflicts', () {
      final result = ConflictDetector.detectConflict(
        localData: {'title': 'Local', 'deletedAt': '2024-01-15'},
        serverData: {'title': 'Server'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime(2024, 1, 15),
        serverUpdatedAt: DateTime(2024, 1, 16),
        entityType: SyncEntityType.score,
      );

      expect(result.hasConflict, isTrue);
      expect(result.conflictType, ConflictType.localDeletedServerModified);
    });

    test('suggests lastWriteWins for scores', () {
      final result = ConflictDetector.detectConflict(
        localData: {'title': 'Local'},
        serverData: {'title': 'Server'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        entityType: SyncEntityType.score,
      );

      expect(result.suggestedResolution, ConflictResolutionStrategy.lastWriteWins);
    });

    test('suggests merge for annotations', () {
      final result = ConflictDetector.detectConflict(
        localData: {'data': 'local-drawing'},
        serverData: {'data': 'server-drawing'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime.now(),
        serverUpdatedAt: DateTime.now(),
        entityType: SyncEntityType.annotation,
      );

      expect(result.suggestedResolution, ConflictResolutionStrategy.merge);
    });
  });

  group('ConflictResolver', () {
    late ConflictResolver resolver;

    setUp(() {
      resolver = ConflictResolver();
    });

    test('keepLocal returns local data with incremented version', () async {
      final conflict = _createTestConflict(
        suggestedResolution: ConflictResolutionStrategy.keepLocal,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.resolvedData, conflict.localData);
      expect(resolved.resolvedVersion, conflict.localVersion + 1);
      expect(resolved.strategy, ConflictResolutionStrategy.keepLocal);
    });

    test('keepServer returns server data', () async {
      final conflict = _createTestConflict(
        suggestedResolution: ConflictResolutionStrategy.keepServer,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.resolvedData, conflict.serverData);
      expect(resolved.resolvedVersion, conflict.serverVersion);
      expect(resolved.strategy, ConflictResolutionStrategy.keepServer);
    });

    test('keepBoth creates duplicate', () async {
      final conflict = _createTestConflict(
        suggestedResolution: ConflictResolutionStrategy.keepBoth,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.createdDuplicate, isTrue);
      expect(resolved.resolvedData['_isDuplicate'], isTrue);
      expect(resolved.resolvedData['_originalId'], conflict.entityId);
    });

    test('lastWriteWins uses newer timestamp - local wins', () async {
      final conflict = _createTestConflict(
        localUpdatedAt: DateTime(2024, 1, 16, 12, 0),
        serverUpdatedAt: DateTime(2024, 1, 15, 12, 0),
        suggestedResolution: ConflictResolutionStrategy.lastWriteWins,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.resolvedData, conflict.localData);
    });

    test('lastWriteWins uses newer timestamp - server wins', () async {
      final conflict = _createTestConflict(
        localUpdatedAt: DateTime(2024, 1, 15, 12, 0),
        serverUpdatedAt: DateTime(2024, 1, 16, 12, 0),
        suggestedResolution: ConflictResolutionStrategy.lastWriteWins,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.resolvedData, conflict.serverData);
    });

    test('merge combines data from both', () async {
      final conflict = SyncConflict(
        entityId: 'entity-1',
        entityType: SyncEntityType.score,
        localData: {'title': 'Local Title', 'composer': 'Local Composer'},
        serverData: {'title': 'Server Title', 'bpm': 120},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime(2024, 1, 15),
        serverUpdatedAt: DateTime(2024, 1, 16),
        suggestedResolution: ConflictResolutionStrategy.merge,
      );

      final resolved = await resolver.resolve(conflict);

      // Should include fields from both
      expect(resolved.resolvedData['bpm'], 120); // From server
      expect(resolved.resolvedData['composer'], 'Local Composer'); // From local
    });

    test('uses default strategy when not specified', () async {
      final conflict = SyncConflict(
        entityId: 'entity-1',
        entityType: SyncEntityType.score,
        localData: {'title': 'Local'},
        serverData: {'title': 'Server'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime(2024, 1, 16),
        serverUpdatedAt: DateTime(2024, 1, 15),
      );

      final resolved = await resolver.resolve(conflict);

      // Default for score is lastWriteWins, local is newer
      expect(resolved.resolvedData, conflict.localData);
    });

    test('manual resolution falls back to lastWriteWins', () async {
      // Resolver without manual callback
      final resolver = ConflictResolver();

      final conflict = _createTestConflict(
        localUpdatedAt: DateTime(2024, 1, 16),
        serverUpdatedAt: DateTime(2024, 1, 15),
        suggestedResolution: ConflictResolutionStrategy.manual,
      );

      final resolved = await resolver.resolve(conflict);

      // Should fall back to lastWriteWins
      expect(resolved.resolvedData, conflict.localData);
    });

    test('manual resolution uses callback result', () async {
      final resolver = ConflictResolver(
        onManualResolution: (conflict) async => ConflictResolutionStrategy.keepServer,
      );

      final conflict = _createTestConflict(
        suggestedResolution: ConflictResolutionStrategy.manual,
      );

      final resolved = await resolver.resolve(conflict);

      expect(resolved.resolvedData, conflict.serverData);
    });
  });

  group('VectorClock', () {
    test('empty clock returns 0 for any node', () {
      final clock = VectorClock();
      expect(clock['node1'], 0);
      expect(clock['node2'], 0);
    });

    test('increment increases node value', () {
      final clock = VectorClock();
      clock.increment('node1');
      expect(clock['node1'], 1);

      clock.increment('node1');
      expect(clock['node1'], 2);
    });

    test('merge takes maximum of each node', () {
      final clock1 = VectorClock({'a': 3, 'b': 2});
      final clock2 = VectorClock({'a': 1, 'b': 5, 'c': 3});

      final merged = clock1.merge(clock2);

      expect(merged['a'], 3);
      expect(merged['b'], 5);
      expect(merged['c'], 3);
    });

    test('compareTo returns equal for identical clocks', () {
      final clock1 = VectorClock({'a': 1, 'b': 2});
      final clock2 = VectorClock({'a': 1, 'b': 2});

      expect(clock1.compareTo(clock2), VectorClockComparison.equal);
    });

    test('compareTo returns after when strictly ahead', () {
      final clock1 = VectorClock({'a': 2, 'b': 3});
      final clock2 = VectorClock({'a': 1, 'b': 2});

      expect(clock1.compareTo(clock2), VectorClockComparison.after);
    });

    test('compareTo returns before when strictly behind', () {
      final clock1 = VectorClock({'a': 1, 'b': 2});
      final clock2 = VectorClock({'a': 2, 'b': 3});

      expect(clock1.compareTo(clock2), VectorClockComparison.before);
    });

    test('compareTo returns concurrent when neither ahead', () {
      final clock1 = VectorClock({'a': 2, 'b': 1});
      final clock2 = VectorClock({'a': 1, 'b': 2});

      expect(clock1.compareTo(clock2), VectorClockComparison.concurrent);
    });

    test('serialize creates string representation', () {
      final clock = VectorClock({'a': 1, 'b': 2});
      final serialized = clock.serialize();

      expect(serialized, contains('a:1'));
      expect(serialized, contains('b:2'));
    });

    test('parse restores clock from string', () {
      final original = VectorClock({'a': 1, 'b': 2});
      final serialized = original.serialize();
      final restored = VectorClock.parse(serialized);

      expect(restored['a'], 1);
      expect(restored['b'], 2);
    });

    test('parse handles empty string', () {
      final clock = VectorClock.parse('');
      expect(clock['any'], 0);
    });

    test('parse handles null', () {
      final clock = VectorClock.parse(null);
      expect(clock['any'], 0);
    });
  });
}

SyncConflict _createTestConflict({
  DateTime? localUpdatedAt,
  DateTime? serverUpdatedAt,
  ConflictResolutionStrategy? suggestedResolution,
}) {
  return SyncConflict(
    entityId: 'entity-1',
    entityType: SyncEntityType.score,
    localData: {'title': 'Local Title'},
    serverData: {'title': 'Server Title'},
    localVersion: 2,
    serverVersion: 3,
    localUpdatedAt: localUpdatedAt ?? DateTime(2024, 1, 15),
    serverUpdatedAt: serverUpdatedAt ?? DateTime(2024, 1, 16),
    suggestedResolution: suggestedResolution,
  );
}
