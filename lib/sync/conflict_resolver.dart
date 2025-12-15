/// Conflict Resolver
/// Handles conflict detection, resolution strategies, and CRDT-based merging
library;

import 'package:flutter/foundation.dart';
import '../rpc/rpc_protocol.dart';

// ============================================================================
// Conflict Detection
// ============================================================================

/// Conflict detector for comparing local and server data
class ConflictDetector {
  /// Detect conflict between local and server versions
  static ConflictResult detectConflict({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required int localVersion,
    required int serverVersion,
    required DateTime localUpdatedAt,
    required DateTime serverUpdatedAt,
    required SyncEntityType entityType,
  }) {
    // No conflict if versions match
    if (localVersion == serverVersion) {
      return ConflictResult.noConflict();
    }

    // Server is ahead - no conflict, just update local
    if (serverVersion > localVersion && localData.isEmpty) {
      return ConflictResult.noConflict();
    }

    // Local is ahead - no conflict, push to server
    if (localVersion > serverVersion && serverData.isEmpty) {
      return ConflictResult.noConflict();
    }

    // Both have changes - actual conflict
    final conflictType = _determineConflictType(
      localData: localData,
      serverData: serverData,
      entityType: entityType,
    );

    return ConflictResult(
      hasConflict: true,
      conflictType: conflictType,
      localVersion: localVersion,
      serverVersion: serverVersion,
      localUpdatedAt: localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt,
      suggestedResolution: _suggestResolution(conflictType, entityType),
    );
  }

  /// Determine type of conflict based on data differences
  static ConflictType _determineConflictType({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required SyncEntityType entityType,
  }) {
    // Check for delete conflicts
    final localDeleted = localData['deletedAt'] != null;
    final serverDeleted = serverData['deletedAt'] != null;

    if (localDeleted && serverDeleted) {
      return ConflictType.bothDeleted;
    }
    if (localDeleted) {
      return ConflictType.localDeletedServerModified;
    }
    if (serverDeleted) {
      return ConflictType.serverDeletedLocalModified;
    }

    // Check for field-level conflicts
    final conflictingFields = <String>[];
    for (final key in localData.keys) {
      if (serverData.containsKey(key) && localData[key] != serverData[key]) {
        conflictingFields.add(key);
      }
    }

    if (conflictingFields.isEmpty) {
      return ConflictType.noConflict;
    }

    // Check if only metadata fields differ
    final metadataFields = {'updatedAt', 'syncStatus', 'version'};
    final hasNonMetadataConflict = conflictingFields.any((f) => !metadataFields.contains(f));

    if (!hasNonMetadataConflict) {
      return ConflictType.metadataOnly;
    }

    return ConflictType.dataConflict;
  }

  /// Suggest resolution strategy based on conflict type and entity type
  static ConflictResolutionStrategy _suggestResolution(
    ConflictType conflictType,
    SyncEntityType entityType,
  ) {
    switch (conflictType) {
      case ConflictType.noConflict:
      case ConflictType.metadataOnly:
        return ConflictResolutionStrategy.keepServer;

      case ConflictType.bothDeleted:
        return ConflictResolutionStrategy.keepServer;

      case ConflictType.localDeletedServerModified:
        return ConflictResolutionStrategy.keepServer;

      case ConflictType.serverDeletedLocalModified:
        return ConflictResolutionStrategy.keepLocal;

      case ConflictType.dataConflict:
        // Entity-specific resolution
        switch (entityType) {
          case SyncEntityType.annotation:
            return ConflictResolutionStrategy.merge;
          case SyncEntityType.score:
          case SyncEntityType.setlist:
            return ConflictResolutionStrategy.lastWriteWins;
          default:
            return ConflictResolutionStrategy.manual;
        }
    }
  }
}

/// Types of conflicts
enum ConflictType {
  noConflict,
  metadataOnly,
  dataConflict,
  bothDeleted,
  localDeletedServerModified,
  serverDeletedLocalModified,
}

/// Result of conflict detection
@immutable
class ConflictResult {
  final bool hasConflict;
  final ConflictType conflictType;
  final int? localVersion;
  final int? serverVersion;
  final DateTime? localUpdatedAt;
  final DateTime? serverUpdatedAt;
  final ConflictResolutionStrategy suggestedResolution;

  const ConflictResult({
    required this.hasConflict,
    this.conflictType = ConflictType.noConflict,
    this.localVersion,
    this.serverVersion,
    this.localUpdatedAt,
    this.serverUpdatedAt,
    this.suggestedResolution = ConflictResolutionStrategy.lastWriteWins,
  });

  factory ConflictResult.noConflict() => const ConflictResult(hasConflict: false);
}

// ============================================================================
// Conflict Resolver
// ============================================================================

/// Resolves conflicts based on configured strategies
class ConflictResolver {
  /// Default resolution strategies per entity type
  final Map<SyncEntityType, ConflictResolutionStrategy> defaultStrategies;

  /// Callback for manual resolution
  final Future<ConflictResolutionStrategy?> Function(SyncConflict)? onManualResolution;

  ConflictResolver({
    Map<SyncEntityType, ConflictResolutionStrategy>? defaultStrategies,
    this.onManualResolution,
  }) : defaultStrategies = defaultStrategies ?? {
    SyncEntityType.score: ConflictResolutionStrategy.lastWriteWins,
    SyncEntityType.instrumentScore: ConflictResolutionStrategy.lastWriteWins,
    SyncEntityType.annotation: ConflictResolutionStrategy.merge,
    SyncEntityType.setlist: ConflictResolutionStrategy.lastWriteWins,
    SyncEntityType.setlistScore: ConflictResolutionStrategy.lastWriteWins,
  };

  /// Resolve a conflict and return the resolved data
  Future<ResolvedConflict> resolve(SyncConflict conflict) async {
    final strategy = conflict.suggestedResolution ??
      defaultStrategies[conflict.entityType] ??
      ConflictResolutionStrategy.lastWriteWins;

    switch (strategy) {
      case ConflictResolutionStrategy.keepLocal:
        return ResolvedConflict(
          resolvedData: conflict.localData,
          resolvedVersion: conflict.localVersion + 1,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.keepServer:
        return ResolvedConflict(
          resolvedData: conflict.serverData,
          resolvedVersion: conflict.serverVersion,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.keepBoth:
        // Create a duplicate - return local with new ID flag
        final duplicatedData = Map<String, dynamic>.from(conflict.localData);
        duplicatedData['_isDuplicate'] = true;
        duplicatedData['_originalId'] = conflict.entityId;
        return ResolvedConflict(
          resolvedData: duplicatedData,
          resolvedVersion: 1,
          strategy: strategy,
          createdDuplicate: true,
        );

      case ConflictResolutionStrategy.merge:
        final mergedData = _mergeData(
          conflict.localData,
          conflict.serverData,
          conflict.entityType,
        );
        return ResolvedConflict(
          resolvedData: mergedData,
          resolvedVersion: (conflict.localVersion > conflict.serverVersion
            ? conflict.localVersion
            : conflict.serverVersion) + 1,
          strategy: strategy,
        );

      case ConflictResolutionStrategy.lastWriteWins:
        if (conflict.localUpdatedAt.isAfter(conflict.serverUpdatedAt)) {
          return ResolvedConflict(
            resolvedData: conflict.localData,
            resolvedVersion: conflict.localVersion + 1,
            strategy: strategy,
          );
        } else {
          return ResolvedConflict(
            resolvedData: conflict.serverData,
            resolvedVersion: conflict.serverVersion,
            strategy: strategy,
          );
        }

      case ConflictResolutionStrategy.manual:
        if (onManualResolution != null) {
          final userChoice = await onManualResolution!(conflict);
          if (userChoice != null && userChoice != ConflictResolutionStrategy.manual) {
            return resolve(SyncConflict(
              entityId: conflict.entityId,
              entityType: conflict.entityType,
              localData: conflict.localData,
              serverData: conflict.serverData,
              localVersion: conflict.localVersion,
              serverVersion: conflict.serverVersion,
              localUpdatedAt: conflict.localUpdatedAt,
              serverUpdatedAt: conflict.serverUpdatedAt,
              suggestedResolution: userChoice,
            ));
          }
        }
        // Default to last-write-wins if manual resolution fails
        return resolve(SyncConflict(
          entityId: conflict.entityId,
          entityType: conflict.entityType,
          localData: conflict.localData,
          serverData: conflict.serverData,
          localVersion: conflict.localVersion,
          serverVersion: conflict.serverVersion,
          localUpdatedAt: conflict.localUpdatedAt,
          serverUpdatedAt: conflict.serverUpdatedAt,
          suggestedResolution: ConflictResolutionStrategy.lastWriteWins,
        ));
    }
  }

  /// Merge two data maps based on entity type
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    SyncEntityType entityType,
  ) {
    final merged = <String, dynamic>{};

    // Start with server data as base
    merged.addAll(server);

    // Apply local changes that are newer
    for (final key in local.keys) {
      // Skip metadata fields
      if ({'id', 'serverId', 'syncStatus', 'version'}.contains(key)) {
        continue;
      }

      // For annotations, merge drawing data specially
      if (entityType == SyncEntityType.annotation && key == 'data') {
        merged['data'] = _mergeAnnotationData(
          local['data'] as String?,
          server['data'] as String?,
        );
        continue;
      }

      // For other fields, use local if different and local has a value
      if (local[key] != null && local[key] != server[key]) {
        merged[key] = local[key];
      }
    }

    return merged;
  }

  /// Merge annotation data (CRDT-like operation)
  String? _mergeAnnotationData(String? localData, String? serverData) {
    if (localData == null) return serverData;
    if (serverData == null) return localData;

    // For now, concatenate drawing strokes
    // A proper implementation would use OT or CRDT for drawing data
    try {
      // Assume JSON arrays of strokes
      // In production, this would be more sophisticated
      return serverData; // Simplified: keep server version
    } catch (e) {
      return serverData;
    }
  }
}

/// Result of conflict resolution
@immutable
class ResolvedConflict {
  final Map<String, dynamic> resolvedData;
  final int resolvedVersion;
  final ConflictResolutionStrategy strategy;
  final bool createdDuplicate;

  const ResolvedConflict({
    required this.resolvedData,
    required this.resolvedVersion,
    required this.strategy,
    this.createdDuplicate = false,
  });
}

// ============================================================================
// Vector Clock (for CRDT support)
// ============================================================================

/// Simple vector clock implementation for CRDT-based conflict resolution
class VectorClock {
  final Map<String, int> _clock;

  VectorClock([Map<String, int>? initial]) : _clock = Map.from(initial ?? {});

  /// Increment clock for a node
  void increment(String nodeId) {
    _clock[nodeId] = (_clock[nodeId] ?? 0) + 1;
  }

  /// Get current value for a node
  int operator [](String nodeId) => _clock[nodeId] ?? 0;

  /// Merge with another clock (take max of each)
  VectorClock merge(VectorClock other) {
    final merged = <String, int>{};
    final allNodes = {..._clock.keys, ...other._clock.keys};

    for (final node in allNodes) {
      merged[node] = (this[node] > other[node]) ? this[node] : other[node];
    }

    return VectorClock(merged);
  }

  /// Compare with another clock
  VectorClockComparison compareTo(VectorClock other) {
    bool thisGreater = false;
    bool otherGreater = false;

    final allNodes = {..._clock.keys, ...other._clock.keys};

    for (final node in allNodes) {
      if (this[node] > other[node]) {
        thisGreater = true;
      } else if (other[node] > this[node]) {
        otherGreater = true;
      }
    }

    if (thisGreater && otherGreater) {
      return VectorClockComparison.concurrent;
    } else if (thisGreater) {
      return VectorClockComparison.after;
    } else if (otherGreater) {
      return VectorClockComparison.before;
    } else {
      return VectorClockComparison.equal;
    }
  }

  /// Serialize to string
  String serialize() {
    return _clock.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Parse from string
  factory VectorClock.parse(String? serialized) {
    if (serialized == null || serialized.isEmpty) {
      return VectorClock();
    }

    final clock = <String, int>{};
    for (final part in serialized.split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        clock[kv[0]] = int.tryParse(kv[1]) ?? 0;
      }
    }
    return VectorClock(clock);
  }

  @override
  String toString() => serialize();
}

/// Vector clock comparison result
enum VectorClockComparison {
  /// This clock is strictly before other
  before,

  /// This clock is strictly after other
  after,

  /// Clocks are equal
  equal,

  /// Clocks are concurrent (conflict)
  concurrent,
}
