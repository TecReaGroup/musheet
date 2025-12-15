/// Offline Operation Queue
/// Manages pending operations for offline-first sync with persistence and ordering
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../rpc/rpc_protocol.dart';

// ============================================================================
// Operation Queue Entry
// ============================================================================

/// Priority levels for queue operations
enum OperationPriority {
  /// Critical operations (deletes, conflict resolutions)
  critical(0),

  /// High priority (user-initiated changes)
  high(1),

  /// Normal priority (background syncs)
  normal(2),

  /// Low priority (prefetch, cache)
  low(3);

  final int value;
  const OperationPriority(this.value);
}

/// Status of a queued operation
enum OperationStatus {
  /// Waiting to be processed
  pending,

  /// Currently being processed
  inProgress,

  /// Completed successfully
  completed,

  /// Failed, will retry
  failed,

  /// Failed permanently, will not retry
  permanentlyFailed,

  /// Cancelled by user
  cancelled,
}

/// A queued operation with metadata
@immutable
class QueuedOperation {
  final String id;
  final SyncOperation operation;
  final OperationPriority priority;
  final OperationStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int attemptCount;
  final String? lastError;
  final List<String> dependsOn;
  final String? idempotencyKey;

  const QueuedOperation({
    required this.id,
    required this.operation,
    this.priority = OperationPriority.normal,
    this.status = OperationStatus.pending,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.attemptCount = 0,
    this.lastError,
    this.dependsOn = const [],
    this.idempotencyKey,
  });

  /// Create new operation
  factory QueuedOperation.create({
    required SyncOperation operation,
    OperationPriority priority = OperationPriority.normal,
    List<String> dependsOn = const [],
    String? idempotencyKey,
  }) {
    return QueuedOperation(
      id: const Uuid().v4(),
      operation: operation,
      priority: priority,
      createdAt: DateTime.now(),
      dependsOn: dependsOn,
      idempotencyKey: idempotencyKey ?? _generateIdempotencyKey(operation),
    );
  }

  /// Generate idempotency key from operation
  static String _generateIdempotencyKey(SyncOperation op) {
    return '${op.entityType.name}:${op.entityId}:${op.operationType.name}:${op.version}';
  }

  QueuedOperation copyWith({
    OperationStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? attemptCount,
    String? lastError,
  }) => QueuedOperation(
    id: id,
    operation: operation,
    priority: priority,
    status: status ?? this.status,
    createdAt: createdAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError,
    dependsOn: dependsOn,
    idempotencyKey: idempotencyKey,
  );

  /// Check if operation can be executed (dependencies satisfied)
  bool canExecute(Set<String> completedIds) {
    if (status != OperationStatus.pending) return false;
    return dependsOn.every((depId) => completedIds.contains(depId));
  }

  /// Check if should retry
  bool get shouldRetry {
    if (status != OperationStatus.failed) return false;
    return attemptCount < 3; // Max 3 attempts
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.toJson(),
    'priority': priority.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'attemptCount': attemptCount,
    'lastError': lastError,
    'dependsOn': dependsOn,
    'idempotencyKey': idempotencyKey,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
    id: json['id'] as String,
    operation: SyncOperation.fromJson(json['operation'] as Map<String, dynamic>),
    priority: OperationPriority.values.byName(json['priority'] as String),
    status: OperationStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    attemptCount: json['attemptCount'] as int? ?? 0,
    lastError: json['lastError'] as String?,
    dependsOn: List<String>.from(json['dependsOn'] as List? ?? []),
    idempotencyKey: json['idempotencyKey'] as String?,
  );
}

// ============================================================================
// Operation Queue
// ============================================================================

/// Persistent operation queue for offline sync
class OperationQueue {
  final List<QueuedOperation> _operations = [];
  final Set<String> _completedIds = {};
  final Set<String> _idempotencyKeys = {};
  final _queueController = StreamController<QueueStats>.broadcast();

  /// Storage interface for persistence
  final Future<void> Function(String data)? onPersist;
  final Future<String?> Function()? onLoad;

  OperationQueue({
    this.onPersist,
    this.onLoad,
  });

  /// Queue statistics stream
  Stream<QueueStats> get statsStream => _queueController.stream;

  /// Current queue stats
  QueueStats get stats => QueueStats(
    pendingCount: _operations.where((op) => op.status == OperationStatus.pending).length,
    inProgressCount: _operations.where((op) => op.status == OperationStatus.inProgress).length,
    failedCount: _operations.where((op) => op.status == OperationStatus.failed).length,
    completedCount: _completedIds.length,
    totalCount: _operations.length,
  );

  /// Initialize queue (load from storage)
  Future<void> initialize() async {
    if (onLoad != null) {
      final data = await onLoad!();
      if (data != null) {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          _loadFromJson(json);
          if (kDebugMode) {
            debugPrint('[OperationQueue] Loaded ${_operations.length} operations from storage');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[OperationQueue] Failed to load from storage: $e');
          }
        }
      }
    }
  }

  /// Enqueue operation
  Future<String> enqueue(
    SyncOperation operation, {
    OperationPriority priority = OperationPriority.normal,
    List<String> dependsOn = const [],
  }) async {
    // Check idempotency
    final idempotencyKey = QueuedOperation._generateIdempotencyKey(operation);
    if (_idempotencyKeys.contains(idempotencyKey)) {
      if (kDebugMode) {
        debugPrint('[OperationQueue] Duplicate operation ignored: $idempotencyKey');
      }
      // Return existing operation ID
      final existing = _operations.firstWhere(
        (op) => op.idempotencyKey == idempotencyKey,
      );
      return existing.id;
    }

    final queuedOp = QueuedOperation.create(
      operation: operation,
      priority: priority,
      dependsOn: dependsOn,
      idempotencyKey: idempotencyKey,
    );

    _operations.add(queuedOp);
    _idempotencyKeys.add(idempotencyKey);
    _sortQueue();
    _notifyStats();
    await _persist();

    if (kDebugMode) {
      debugPrint('[OperationQueue] Enqueued: ${operation.entityType.name}.${operation.operationType.name}');
    }

    return queuedOp.id;
  }

  /// Batch enqueue operations
  Future<List<String>> enqueueBatch(List<SyncOperation> operations) async {
    final ids = <String>[];
    for (final op in operations) {
      final id = await enqueue(op);
      ids.add(id);
    }
    return ids;
  }

  /// Get next operation to process
  QueuedOperation? getNext() {
    for (final op in _operations) {
      if (op.canExecute(_completedIds)) {
        return op;
      }
    }
    return null;
  }

  /// Get all pending operations
  List<QueuedOperation> getPending() {
    return _operations
      .where((op) => op.status == OperationStatus.pending && op.canExecute(_completedIds))
      .toList();
  }

  /// Get operations by entity
  List<QueuedOperation> getByEntity(SyncEntityType type, String entityId) {
    return _operations
      .where((op) => op.operation.entityType == type && op.operation.entityId == entityId)
      .toList();
  }

  /// Mark operation as started
  Future<void> markStarted(String operationId) async {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      _operations[index] = _operations[index].copyWith(
        status: OperationStatus.inProgress,
        startedAt: DateTime.now(),
        attemptCount: _operations[index].attemptCount + 1,
      );
      _notifyStats();
      await _persist();
    }
  }

  /// Mark operation as completed
  Future<void> markCompleted(String operationId) async {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      _operations[index] = _operations[index].copyWith(
        status: OperationStatus.completed,
        completedAt: DateTime.now(),
      );
      _completedIds.add(operationId);
      _notifyStats();
      await _persist();
    }
  }

  /// Mark operation as failed
  Future<void> markFailed(String operationId, String error) async {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      final op = _operations[index];
      final newStatus = op.attemptCount >= 3
        ? OperationStatus.permanentlyFailed
        : OperationStatus.failed;

      _operations[index] = op.copyWith(
        status: newStatus,
        lastError: error,
      );
      _notifyStats();
      await _persist();
    }
  }

  /// Retry failed operations
  Future<int> retryFailed() async {
    int count = 0;
    for (int i = 0; i < _operations.length; i++) {
      if (_operations[i].shouldRetry) {
        _operations[i] = _operations[i].copyWith(
          status: OperationStatus.pending,
        );
        count++;
      }
    }
    if (count > 0) {
      _sortQueue();
      _notifyStats();
      await _persist();
    }
    return count;
  }

  /// Cancel operation
  Future<bool> cancel(String operationId) async {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      _operations[index] = _operations[index].copyWith(
        status: OperationStatus.cancelled,
      );
      _notifyStats();
      await _persist();
      return true;
    }
    return false;
  }

  /// Clear completed and cancelled operations
  Future<int> prune() async {
    final before = _operations.length;
    _operations.removeWhere((op) =>
      op.status == OperationStatus.completed ||
      op.status == OperationStatus.cancelled
    );
    final removed = before - _operations.length;
    if (removed > 0) {
      await _persist();
    }
    return removed;
  }

  /// Clear all operations
  Future<void> clear() async {
    _operations.clear();
    _completedIds.clear();
    _idempotencyKeys.clear();
    _notifyStats();
    await _persist();
  }

  /// Sort queue by priority and creation time
  void _sortQueue() {
    _operations.sort((a, b) {
      // First by priority
      final priorityCompare = a.priority.value.compareTo(b.priority.value);
      if (priorityCompare != 0) return priorityCompare;
      // Then by creation time
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  /// Notify stats update
  void _notifyStats() {
    _queueController.add(stats);
  }

  /// Persist to storage
  Future<void> _persist() async {
    if (onPersist != null) {
      final json = _toJson();
      await onPersist!(jsonEncode(json));
    }
  }

  Map<String, dynamic> _toJson() => {
    'operations': _operations.map((op) => op.toJson()).toList(),
    'completedIds': _completedIds.toList(),
    'idempotencyKeys': _idempotencyKeys.toList(),
  };

  void _loadFromJson(Map<String, dynamic> json) {
    _operations.clear();
    _completedIds.clear();
    _idempotencyKeys.clear();

    final ops = json['operations'] as List? ?? [];
    for (final op in ops) {
      _operations.add(QueuedOperation.fromJson(op as Map<String, dynamic>));
    }

    final completed = json['completedIds'] as List? ?? [];
    _completedIds.addAll(completed.cast<String>());

    final keys = json['idempotencyKeys'] as List? ?? [];
    _idempotencyKeys.addAll(keys.cast<String>());

    _sortQueue();
  }

  /// Dispose resources
  void dispose() {
    _queueController.close();
  }
}

/// Queue statistics
@immutable
class QueueStats {
  final int pendingCount;
  final int inProgressCount;
  final int failedCount;
  final int completedCount;
  final int totalCount;

  const QueueStats({
    this.pendingCount = 0,
    this.inProgressCount = 0,
    this.failedCount = 0,
    this.completedCount = 0,
    this.totalCount = 0,
  });

  bool get isEmpty => totalCount == 0;
  bool get hasPending => pendingCount > 0;
  bool get hasFailed => failedCount > 0;

  @override
  String toString() => 'QueueStats(pending: $pendingCount, inProgress: $inProgressCount, failed: $failedCount)';
}
