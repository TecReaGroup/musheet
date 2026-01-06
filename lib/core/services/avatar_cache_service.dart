import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/remote/api_client.dart';
import '../../utils/logger.dart';

/// Avatar cache service with two-level caching:
/// 1. Memory cache - Fast access, cleared on app restart
/// 2. Disk cache - Persistent, survives app restart (for offline support)
class AvatarCacheService {
  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;
  AvatarCacheService._internal();

  /// Memory cache: userId -> avatar bytes
  final Map<int, Uint8List?> _memoryCache = {};

  /// Check if avatar is in memory cache (for fast synchronous access)
  bool isInMemoryCache(int userId) => _memoryCache.containsKey(userId);

  /// Get avatar from memory cache synchronously (returns null if not cached)
  Uint8List? getFromMemoryCache(int userId) => _memoryCache[userId];

  /// Get avatar directory path
  Future<String> _getAvatarDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = p.join(appDir.path, 'avatars');
    await Directory(avatarDir).create(recursive: true);
    return avatarDir;
  }

  /// Get avatar file path for a user
  Future<String> _getAvatarPath(int userId) async {
    final dir = await _getAvatarDir();
    return p.join(dir, '$userId.jpg');
  }

  /// Get avatar with two-level caching
  /// Priority: Memory -> Disk -> Network
  Future<Uint8List?> getAvatar(int userId) async {
    // Level 1: Check memory cache
    if (_memoryCache.containsKey(userId)) {
      Log.d('AVATAR', 'Memory cache hit for user $userId');
      return _memoryCache[userId];
    }

    // Level 2: Check disk cache
    try {
      final avatarPath = await _getAvatarPath(userId);
      final file = File(avatarPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _memoryCache[userId] = bytes;
        Log.d('AVATAR', 'Disk cache hit for user $userId');
        return bytes;
      }
    } catch (e) {
      Log.e('AVATAR', 'Failed to read disk cache for user $userId', error: e);
    }

    // Level 3: Fetch from network
    try {
      if (!ApiClient.isInitialized) {
        _memoryCache[userId] = null;
        return null;
      }

      Log.d('AVATAR', 'Fetching avatar from network for user $userId');
      final result = await ApiClient.instance.getAvatar(userId);
      
      if (result.isSuccess && result.data != null) {
        final bytes = result.data!;
        
        // Save to memory cache
        _memoryCache[userId] = bytes;
        
        // Save to disk cache (async, don't block)
        _saveToDisk(userId, bytes).catchError((e) {
          Log.e('AVATAR', 'Failed to save avatar to disk for user $userId', error: e);
        });
        
        return bytes;
      } else {
        _memoryCache[userId] = null;
        return null;
      }
    } catch (e) {
      Log.e('AVATAR', 'Failed to fetch avatar for user $userId', error: e);
      _memoryCache[userId] = null;
      return null;
    }
  }

  /// Save avatar to disk cache
  Future<void> _saveToDisk(int userId, Uint8List bytes) async {
    try {
      final avatarPath = await _getAvatarPath(userId);
      final file = File(avatarPath);
      await file.writeAsBytes(bytes);
      Log.d('AVATAR', 'Saved avatar to disk for user $userId');
    } catch (e) {
      Log.e('AVATAR', 'Failed to save avatar to disk for user $userId', error: e);
    }
  }

  /// Clear memory cache (called on app restart to refresh avatars)
  void clearMemoryCache() {
    _memoryCache.clear();
    Log.d('AVATAR', 'Memory cache cleared');
  }

  /// Clear both memory and disk cache (e.g., on logout)
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    try {
      final dir = await _getAvatarDir();
      final avatarDir = Directory(dir);
      if (await avatarDir.exists()) {
        await avatarDir.delete(recursive: true);
        Log.d('AVATAR', 'All cache cleared');
      }
    } catch (e) {
      Log.e('AVATAR', 'Failed to clear disk cache', error: e);
    }
  }

  /// Remove specific user's avatar from cache
  Future<void> removeAvatar(int userId) async {
    _memoryCache.remove(userId);
    try {
      final avatarPath = await _getAvatarPath(userId);
      final file = File(avatarPath);
      if (await file.exists()) {
        await file.delete();
        Log.d('AVATAR', 'Removed avatar for user $userId');
      }
    } catch (e) {
      Log.e('AVATAR', 'Failed to remove avatar for user $userId', error: e);
    }
  }

  /// Prefetch avatars for multiple users (e.g., team members)
  Future<void> prefetchAvatars(List<int> userIds) async {
    Log.d('AVATAR', 'Prefetching ${userIds.length} avatars');
    await Future.wait(
      userIds.map((userId) => getAvatar(userId)),
      eagerError: false,
    );
  }
}
