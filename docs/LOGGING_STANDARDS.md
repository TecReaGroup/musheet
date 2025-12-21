# Logging Standards / 日志规范

This document defines the logging conventions for the MuSheet codebase, covering both frontend (Flutter) and backend (Serverpod).

## Overview / 概述

### Goals / 目标
- **Consistency**: Uniform log format across all modules
- **Readability**: Easy to filter and search logs
- **Performance**: No logging overhead in production builds
- **Debugging**: Sufficient context for troubleshooting

---

## Frontend (Flutter) Logging / 前端日志

### Log Utility / 日志工具

Use the centralized logging utility located at `lib/utils/logger.dart`:

```dart
import '../utils/logger.dart';

// Usage:
Log.d('TAG', 'Debug message');
Log.i('TAG', 'Info message');
Log.w('TAG', 'Warning message');
Log.e('TAG', 'Error message', error: e, stackTrace: s);
```

### Log Levels / 日志级别

| Level | Method | Usage |
|-------|--------|-------|
| DEBUG | `Log.d()` | Detailed internal state, variable values |
| INFO | `Log.i()` | Key operations, state changes |
| WARN | `Log.w()` | Recoverable issues, unexpected states |
| ERROR | `Log.e()` | Failures, exceptions |

### Tag Naming Convention / 标签命名规范

Use short, uppercase tags (max 12 characters):

| Module | Tag |
|--------|-----|
| Authentication | `AUTH` |
| Database Service | `DB` |
| Library Sync | `SYNC` |
| PDF Sync | `PDF` |
| RPC Client | `RPC` |
| Providers | `PROV` |
| Backend Service | `API` |
| File Storage | `FILE` |

### Format / 格式

```
[TAG] message
```

Examples:
```
[AUTH] Login successful: userId=123
[SYNC] Push started: 5 pending changes
[DB] Score created: id=abc-123, title="Symphony No. 5"
[RPC] Request failed: /librarySync/push, error=timeout
```

### Rules / 规则

1. **Production Safety**: All logs are wrapped with `kDebugMode` check
2. **No Sensitive Data**: Never log passwords, tokens (except partial), or personal data
3. **Concise Messages**: Keep messages short but informative
4. **No Emoji**: Do not use emoji in logs (reserved for UI)
5. **Action Indicators**: Use simple text indicators
   - Success: `success` or `ok`
   - Failure: `failed` or `error`
   - Warning: `warning`

### What NOT to Log / 不应记录

- Every database read operation (too verbose)
- Successful routine operations (only log key milestones)
- Full object dumps (log only relevant fields)
- User-identifiable information (use IDs instead)

---

## Backend (Serverpod) Logging / 后端日志

### Log Method / 日志方法

Use Serverpod's `session.log()` with appropriate `LogLevel`:

```dart
session.log('[TAG] message', level: LogLevel.info);
session.log('[TAG] message', level: LogLevel.debug);
session.log('[TAG] message', level: LogLevel.warning);
session.log('[TAG] message', level: LogLevel.error);
```

### Log Levels / 日志级别

| Level | Usage |
|-------|-------|
| `LogLevel.debug` | Detailed debugging info, not for production |
| `LogLevel.info` | Normal operations, key events |
| `LogLevel.warning` | Potential issues, conflicts, recoverable errors |
| `LogLevel.error` | Failures, exceptions |

### Tag Naming Convention / 标签命名规范

Use short, uppercase tags in brackets:

| Endpoint | Tag |
|----------|-----|
| Library Sync | `SYNC` |
| File Operations | `FILE` |
| Score Operations | `SCORE` |
| Setlist Operations | `SETLIST` |
| Authentication | `AUTH` |
| Profile | `PROFILE` |
| Team | `TEAM` |
| Admin | `ADMIN` |

### Format / 格式

```
[TAG] action: details
```

Examples:
```
[SYNC] Pull started: userId=123, since=2024-01-01T00:00:00Z
[FILE] PDF uploaded: hash=abc123, size=1048576
[SCORE] Update conflict: clientVersion=3, serverVersion=5
[AUTH] Login failed: username=john, reason=invalid_password
```

### Rules / 规则

1. **No Decorative Boxes**: Do not use ASCII art boxes (`╔`, `║`, `╚`)
2. **No Emoji**: Do not use emoji (keep logs machine-parseable)
3. **Structured Messages**: Use `key=value` format for parameters
4. **Request Context**: Include userId and relevant IDs
5. **Error Details**: Include error type and message

### Log Level Guidelines / 日志级别指南

- **DEBUG**: Internal state, query results, intermediate values
- **INFO**: Operation start/complete, key business events
- **WARNING**: Version conflicts, permission denied, data issues
- **ERROR**: Exceptions, operation failures

---

## Migration Guide / 迁移指南

### Frontend Migration

Before:
```dart
if (kDebugMode) {
  debugPrint('[DatabaseService] Creating score: ${score.title}');
}
```

After:
```dart
Log.d('DB', 'Creating score: title="${score.title}"');
```

### Backend Migration

Before:
```dart
session.log('╔════════════════════════════════════════════╗', level: LogLevel.info);
session.log('║     SCORE.upsertScore CALLED               ║', level: LogLevel.info);
session.log('╚════════════════════════════════════════════╝', level: LogLevel.info);
session.log('[SCORE] ✅ Updated score: ${score.title}', level: LogLevel.info);
```

After:
```dart
session.log('[SCORE] Upsert called: id=${score.id}, title="${score.title}"', level: LogLevel.info);
session.log('[SCORE] Update success: title="${score.title}", version=${score.version}', level: LogLevel.info);
```

---

## Logging Checklist / 日志检查清单

### For Code Reviews / 代码审查

- [ ] Uses correct tag format `[TAG]`
- [ ] Uses appropriate log level
- [ ] No sensitive data logged
- [ ] No decorative characters or emoji
- [ ] Follows `key=value` format for parameters
- [ ] Frontend logs wrapped in `kDebugMode` (via Log utility)

---

## Examples / 示例

### Good Examples / 好的示例

```dart
// Frontend
Log.i('AUTH', 'Login success: userId=123');
Log.d('SYNC', 'Push started: pendingCount=5');
Log.w('DB', 'Score not found: id=abc-123');
Log.e('RPC', 'Request failed: endpoint=/sync/push', error: e);

// Backend
session.log('[SYNC] Pull request: userId=123, since=2024-01-01', level: LogLevel.info);
session.log('[FILE] Upload complete: hash=abc123, bytes=1048576', level: LogLevel.info);
session.log('[SCORE] Version conflict: client=3, server=5', level: LogLevel.warning);
```

### Bad Examples / 不好的示例

```dart
// Too verbose
debugPrint('[DatabaseService] Starting to save score to database...');

// Decorative (avoid)
session.log('═══════════════════════════════', level: LogLevel.info);

// Emoji (avoid)
session.log('[SCORE] ✅ Success!', level: LogLevel.info);

// Missing context
Log.i('SYNC', 'Done');

// Sensitive data
Log.d('AUTH', 'Token: $authToken');
```
