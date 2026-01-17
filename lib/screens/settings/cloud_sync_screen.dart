import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../router/app_router.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/core_providers.dart';

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  bool _isSyncing = false;
  String? _syncMessage;

  Future<void> _triggerSync() async {
    final syncCoordinator = ref.read(syncCoordinatorProvider);

    if (syncCoordinator == null) {
      setState(() {
        _syncMessage = 'Sync service not available';
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final result = await syncCoordinator.syncNow();
      setState(() {
        _isSyncing = false;
        if (result.success) {
          _syncMessage =
              'Synced: ${result.pushedCount} uploaded, ${result.pulledCount} downloaded';
        } else {
          _syncMessage = result.error ?? 'Sync failed';
        }
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.isAuthenticated;
    // Watch sync state for showing last sync time and status
    final syncState = ref.watch(currentSyncStateProvider);
    // Watch connection state for network status
    final connectionAsync = ref.watch(connectionStateProvider);
    final isOnline = connectionAsync.whenOrNull(
          data: (state) => state.isConnected,
        ) ??
        false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(AppRoutes.settings);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.gray200)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.settings),
                        icon: const Icon(
                          AppIcons.chevronLeft,
                          color: AppColors.gray600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Cloud Sync',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isLoggedIn
                              ? AppColors.emerald50
                              : AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLoggedIn ? AppIcons.cloud : AppIcons.cloudOff,
                          size: 56,
                          color: isLoggedIn
                              ? AppColors.emerald500
                              : AppColors.gray400,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Status text
                      Text(
                        isLoggedIn ? 'Cloud Sync On' : 'Cloud Sync Off',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: isLoggedIn
                              ? AppColors.emerald600
                              : AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        isLoggedIn
                            ? 'Your scores and setlists are syncing automatically'
                            : 'Sign in to sync your data across devices',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Status indicators - Network and Account
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Network status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.emerald50
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isOnline
                                    ? AppColors.emerald200
                                    : AppColors.gray200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? AppColors.emerald500
                                        : AppColors.gray400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isOnline
                                        ? AppColors.emerald600
                                        : AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Account status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isLoggedIn
                                  ? AppColors.blue50
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isLoggedIn
                                    ? AppColors.blue200
                                    : AppColors.gray200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLoggedIn ? AppIcons.check : AppIcons.person,
                                  size: 14,
                                  color: isLoggedIn
                                      ? AppColors.blue500
                                      : AppColors.gray400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isLoggedIn ? 'Logged in' : 'Not logged in',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isLoggedIn
                                        ? AppColors.blue600
                                        : AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Sync button (only show when logged in)
                      if (isLoggedIn) ...[
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _triggerSync,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(AppIcons.sync),
                          label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        // Last sync info
                        if (syncState.lastSyncAt != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Last synced: ${_formatTime(syncState.lastSyncAt!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                        // Sync message
                        if (_syncMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _syncMessage!.startsWith('Error') ||
                                      _syncMessage!.startsWith('Sync failed')
                                  ? AppColors.red50
                                  : AppColors.blue50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _syncMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    _syncMessage!.startsWith('Error') ||
                                        _syncMessage!.startsWith('Sync failed')
                                    ? AppColors.red600
                                    : AppColors.blue600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
