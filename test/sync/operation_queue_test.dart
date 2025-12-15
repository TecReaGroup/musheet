import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/sync/operation_queue.dart';
import 'package:musheet/rpc/rpc_protocol.dart';

void main() {
  group('QueuedOperation', () {
    test('create generates unique ID', () {
      final op1 = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
      );
      final op2 = QueuedOperation.create(
        operation: _createTestOperation('entity-2'),
      );

      expect(op1.id, isNot(op2.id));
    });

    test('creates with pending status', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
      );

      expect(op.status, OperationStatus.pending);
      expect(op.attemptCount, 0);
    });

    test('generates idempotency key', () {
      final operation = _createTestOperation('entity-1');
      final op = QueuedOperation.create(operation: operation);

      expect(op.idempotencyKey, isNotNull);
      expect(op.idempotencyKey, contains('score'));
      expect(op.idempotencyKey, contains('entity-1'));
    });

    test('canExecute returns true when dependencies are satisfied', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
        dependsOn: ['dep-1', 'dep-2'],
      );

      expect(op.canExecute({}), isFalse);
      expect(op.canExecute({'dep-1'}), isFalse);
      expect(op.canExecute({'dep-1', 'dep-2'}), isTrue);
    });

    test('canExecute returns false for non-pending status', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
      ).copyWith(status: OperationStatus.inProgress);

      expect(op.canExecute({}), isFalse);
    });

    test('shouldRetry returns true for failed with low attempt count', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
      ).copyWith(
        status: OperationStatus.failed,
        attemptCount: 1,
      );

      expect(op.shouldRetry, isTrue);
    });

    test('shouldRetry returns false for too many attempts', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
      ).copyWith(
        status: OperationStatus.failed,
        attemptCount: 3,
      );

      expect(op.shouldRetry, isFalse);
    });

    test('serializes and deserializes correctly', () {
      final op = QueuedOperation.create(
        operation: _createTestOperation('entity-1'),
        priority: OperationPriority.high,
        dependsOn: ['dep-1'],
      );

      final json = op.toJson();
      final restored = QueuedOperation.fromJson(json);

      expect(restored.id, op.id);
      expect(restored.priority, op.priority);
      expect(restored.status, op.status);
      expect(restored.dependsOn, op.dependsOn);
      expect(restored.idempotencyKey, op.idempotencyKey);
    });
  });

  group('OperationQueue', () {
    late OperationQueue queue;

    setUp(() {
      queue = OperationQueue();
    });

    tearDown(() {
      queue.dispose();
    });

    test('starts empty', () {
      expect(queue.stats.isEmpty, isTrue);
      expect(queue.stats.totalCount, 0);
    });

    test('enqueue adds operation', () async {
      await queue.enqueue(_createTestOperation('entity-1'));

      expect(queue.stats.totalCount, 1);
      expect(queue.stats.pendingCount, 1);
    });

    test('enqueue ignores duplicate idempotency keys', () async {
      final op = _createTestOperation('entity-1');

      final id1 = await queue.enqueue(op);
      final id2 = await queue.enqueue(op);

      expect(id1, id2);
      expect(queue.stats.totalCount, 1);
    });

    test('getNext returns first pending operation', () async {
      await queue.enqueue(_createTestOperation('entity-1'));
      await queue.enqueue(_createTestOperation('entity-2'));

      final next = queue.getNext();
      expect(next, isNotNull);
      expect(next!.operation.entityId, 'entity-1');
    });

    test('getNext respects priority', () async {
      await queue.enqueue(
        _createTestOperation('entity-low'),
        priority: OperationPriority.low,
      );
      await queue.enqueue(
        _createTestOperation('entity-high'),
        priority: OperationPriority.high,
      );

      final next = queue.getNext();
      expect(next!.operation.entityId, 'entity-high');
    });

    test('getNext respects dependencies', () async {
      final depId = await queue.enqueue(_createTestOperation('entity-dep'));
      await queue.enqueue(
        _createTestOperation('entity-dependent'),
        dependsOn: [depId],
      );

      // First should be the dependency
      final next = queue.getNext();
      expect(next!.operation.entityId, 'entity-dep');
    });

    test('getPending returns all executable operations', () async {
      await queue.enqueue(_createTestOperation('entity-1'));
      await queue.enqueue(_createTestOperation('entity-2'));

      final pending = queue.getPending();
      expect(pending.length, 2);
    });

    test('getByEntity returns matching operations', () async {
      await queue.enqueue(_createTestOperation('entity-1'));
      await queue.enqueue(_createTestOperation('entity-1'));
      await queue.enqueue(_createTestOperation('entity-2'));

      final matches = queue.getByEntity(SyncEntityType.score, 'entity-1');
      expect(matches.length, 2);
    });

    test('markStarted updates status', () async {
      final id = await queue.enqueue(_createTestOperation('entity-1'));
      await queue.markStarted(id);

      expect(queue.stats.inProgressCount, 1);
      expect(queue.stats.pendingCount, 0);
    });

    test('markCompleted updates status', () async {
      final id = await queue.enqueue(_createTestOperation('entity-1'));
      await queue.markStarted(id);
      await queue.markCompleted(id);

      expect(queue.stats.completedCount, 1);
      expect(queue.stats.inProgressCount, 0);
    });

    test('markFailed updates status', () async {
      final id = await queue.enqueue(_createTestOperation('entity-1'));
      await queue.markStarted(id);
      await queue.markFailed(id, 'Network error');

      expect(queue.stats.failedCount, 1);
    });

    test('retryFailed resets failed operations', () async {
      final id = await queue.enqueue(_createTestOperation('entity-1'));
      await queue.markStarted(id);
      await queue.markFailed(id, 'Network error');

      final retried = await queue.retryFailed();
      expect(retried, 1);
      expect(queue.stats.pendingCount, 1);
      expect(queue.stats.failedCount, 0);
    });

    test('cancel marks operation as cancelled', () async {
      final id = await queue.enqueue(_createTestOperation('entity-1'));
      final result = await queue.cancel(id);

      expect(result, isTrue);
    });

    test('prune removes completed and cancelled', () async {
      final id1 = await queue.enqueue(_createTestOperation('entity-1'));
      final id2 = await queue.enqueue(_createTestOperation('entity-2'));
      await queue.enqueue(_createTestOperation('entity-3'));

      await queue.markStarted(id1);
      await queue.markCompleted(id1);
      await queue.cancel(id2);

      final removed = await queue.prune();
      expect(removed, 2);
      expect(queue.stats.totalCount, 1);
    });

    test('clear removes all operations', () async {
      await queue.enqueue(_createTestOperation('entity-1'));
      await queue.enqueue(_createTestOperation('entity-2'));

      await queue.clear();
      expect(queue.stats.isEmpty, isTrue);
    });

    test('enqueueBatch adds multiple operations', () async {
      final ops = [
        _createTestOperation('entity-1'),
        _createTestOperation('entity-2'),
        _createTestOperation('entity-3'),
      ];

      final ids = await queue.enqueueBatch(ops);
      expect(ids.length, 3);
      expect(queue.stats.totalCount, 3);
    });

    test('stats stream emits on changes', () async {
      final stats = <QueueStats>[];
      queue.statsStream.listen(stats.add);

      await queue.enqueue(_createTestOperation('entity-1'));
      await Future.delayed(Duration.zero);

      expect(stats.length, greaterThan(0));
    });

    test('persistence callbacks are called', () async {
      String? persistedData;

      final persistentQueue = OperationQueue(
        onPersist: (data) async => persistedData = data,
        onLoad: () async => null,
      );

      await persistentQueue.enqueue(_createTestOperation('entity-1'));

      expect(persistedData, isNotNull);
      expect(persistedData, contains('entity-1'));

      persistentQueue.dispose();
    });
  });

  group('QueueStats', () {
    test('isEmpty returns true when no operations', () {
      const stats = QueueStats();
      expect(stats.isEmpty, isTrue);
    });

    test('hasPending returns true when pending > 0', () {
      const stats = QueueStats(pendingCount: 1);
      expect(stats.hasPending, isTrue);
    });

    test('hasFailed returns true when failed > 0', () {
      const stats = QueueStats(failedCount: 1);
      expect(stats.hasFailed, isTrue);
    });
  });
}

SyncOperation _createTestOperation(String entityId) {
  return SyncOperation(
    id: 'op-$entityId',
    entityType: SyncEntityType.score,
    entityId: entityId,
    operationType: SyncOperationType.update,
    data: {'title': 'Test'},
    version: 1,
    createdAt: DateTime.now(),
  );
}
