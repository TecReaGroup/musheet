import 'package:flutter_test/flutter_test.dart';
import 'package:musheet/rpc/rpc_protocol.dart';

void main() {
  group('RpcProtocolVersion', () {
    test('version string format', () {
      expect(RpcProtocolVersion.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('isCompatible returns true for same major version', () {
      expect(RpcProtocolVersion.isCompatible('2.0.0'), isTrue);
      expect(RpcProtocolVersion.isCompatible('2.1.0'), isTrue);
      expect(RpcProtocolVersion.isCompatible('2.5.3'), isTrue);
    });

    test('isCompatible returns false for different major version', () {
      expect(RpcProtocolVersion.isCompatible('1.0.0'), isFalse);
      expect(RpcProtocolVersion.isCompatible('3.0.0'), isFalse);
    });

    test('isCompatible handles invalid versions', () {
      expect(RpcProtocolVersion.isCompatible('invalid'), isFalse);
      expect(RpcProtocolVersion.isCompatible(''), isFalse);
    });
  });

  group('RpcErrorCode', () {
    test('fromCode returns correct error', () {
      expect(RpcErrorCode.fromCode(1001), RpcErrorCode.networkUnavailable);
      expect(RpcErrorCode.fromCode(2001), RpcErrorCode.authenticationRequired);
      expect(RpcErrorCode.fromCode(5001), RpcErrorCode.syncConflict);
    });

    test('fromCode returns unknown for invalid codes', () {
      expect(RpcErrorCode.fromCode(0), RpcErrorCode.unknown);
      expect(RpcErrorCode.fromCode(99999), RpcErrorCode.unknown);
    });

    test('isRetryable returns correct values', () {
      expect(RpcErrorCode.networkUnavailable.isRetryable, isTrue);
      expect(RpcErrorCode.connectionTimeout.isRetryable, isTrue);
      expect(RpcErrorCode.tokenExpired.isRetryable, isTrue);
      expect(RpcErrorCode.rateLimited.isRetryable, isTrue);

      expect(RpcErrorCode.authenticationRequired.isRetryable, isFalse);
      expect(RpcErrorCode.resourceNotFound.isRetryable, isFalse);
      expect(RpcErrorCode.invalidRequest.isRetryable, isFalse);
    });
  });

  group('RpcError', () {
    test('creates with default message', () {
      final error = RpcError(code: RpcErrorCode.networkUnavailable);
      expect(error.message, 'Network unavailable');
    });

    test('creates with custom message', () {
      final error = RpcError(
        code: RpcErrorCode.networkUnavailable,
        message: 'Custom message',
      );
      expect(error.message, 'Custom message');
    });

    test('fromException detects network errors', () {
      final error = RpcError.fromException(Exception('SocketException: Connection refused'));
      expect(error.code, RpcErrorCode.networkUnavailable);
    });

    test('fromException detects timeout errors', () {
      final error = RpcError.fromException(Exception('TimeoutException'));
      expect(error.code, RpcErrorCode.connectionTimeout);
    });

    test('fromException detects auth errors', () {
      final error = RpcError.fromException(Exception('401 Unauthorized'));
      expect(error.code, RpcErrorCode.authenticationRequired);
    });

    test('toJson contains all fields', () {
      final error = RpcError(
        code: RpcErrorCode.syncConflict,
        message: 'Conflict detected',
        details: 'Version mismatch',
        requestId: 'req-123',
      );

      final json = error.toJson();
      expect(json['code'], 5001);
      expect(json['codeName'], 'syncConflict');
      expect(json['message'], 'Conflict detected');
      expect(json['details'], 'Version mismatch');
      expect(json['requestId'], 'req-123');
    });
  });

  group('RpcRequest', () {
    test('generates unique request IDs', () {
      final req1 = RpcRequest(endpoint: 'test', method: 'test', payload: null);
      final req2 = RpcRequest(endpoint: 'test', method: 'test', payload: null);
      expect(req1.requestId, isNot(req2.requestId));
    });

    test('retry increments retry count', () {
      final req = RpcRequest(endpoint: 'test', method: 'test', payload: null);
      expect(req.retryCount, 0);

      final retry1 = req.retry();
      expect(retry1.retryCount, 1);
      expect(retry1.requestId, req.requestId); // Same request ID

      final retry2 = retry1.retry();
      expect(retry2.retryCount, 2);
    });
  });

  group('RpcResponse', () {
    test('success response properties', () {
      final response = RpcResponse.success(
        'data',
        requestId: 'req-123',
        latency: const Duration(milliseconds: 100),
      );

      expect(response.isSuccess, isTrue);
      expect(response.isError, isFalse);
      expect(response.data, 'data');
      expect(response.error, isNull);
    });

    test('failure response properties', () {
      final response = RpcResponse<String>.failure(
        RpcError(code: RpcErrorCode.networkUnavailable),
        requestId: 'req-123',
      );

      expect(response.isSuccess, isFalse);
      expect(response.isError, isTrue);
      expect(response.data, isNull);
      expect(response.error, isNotNull);
    });

    test('map transforms data', () {
      final response = RpcResponse.success(
        10,
        requestId: 'req-123',
      );

      final mapped = response.map((data) => data * 2);
      expect(mapped.data, 20);
    });

    test('map preserves error on failure', () {
      final response = RpcResponse<int>.failure(
        RpcError(code: RpcErrorCode.networkUnavailable),
        requestId: 'req-123',
      );

      final mapped = response.map((data) => data * 2);
      expect(mapped.isError, isTrue);
    });
  });

  group('SyncOperation', () {
    test('serializes and deserializes correctly', () {
      final operation = SyncOperation(
        id: 'op-123',
        entityType: SyncEntityType.score,
        entityId: 'score-456',
        operationType: SyncOperationType.update,
        data: {'title': 'Test Score'},
        version: 2,
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      final json = operation.toJson();
      final restored = SyncOperation.fromJson(json);

      expect(restored.id, operation.id);
      expect(restored.entityType, operation.entityType);
      expect(restored.entityId, operation.entityId);
      expect(restored.operationType, operation.operationType);
      expect(restored.data, operation.data);
      expect(restored.version, operation.version);
    });

    test('retry increments retry count', () {
      final operation = SyncOperation(
        id: 'op-123',
        entityType: SyncEntityType.score,
        entityId: 'score-456',
        operationType: SyncOperationType.create,
        data: {},
        version: 1,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final retry = operation.retry();
      expect(retry.retryCount, 1);
      expect(retry.id, operation.id);
    });
  });

  group('SyncConflict', () {
    test('toJson includes all fields', () {
      final conflict = SyncConflict(
        entityId: 'score-123',
        entityType: SyncEntityType.score,
        localData: {'title': 'Local Title'},
        serverData: {'title': 'Server Title'},
        localVersion: 2,
        serverVersion: 3,
        localUpdatedAt: DateTime(2024, 1, 15),
        serverUpdatedAt: DateTime(2024, 1, 16),
        suggestedResolution: ConflictResolutionStrategy.lastWriteWins,
      );

      final json = conflict.toJson();
      expect(json['entityId'], 'score-123');
      expect(json['entityType'], 'score');
      expect(json['localVersion'], 2);
      expect(json['serverVersion'], 3);
      expect(json['suggestedResolution'], 'lastWriteWins');
    });
  });
}
