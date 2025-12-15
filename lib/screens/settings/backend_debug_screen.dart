import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../router/app_router.dart';
import '../../services/backend_service.dart';
import '../../services/sync_service.dart';
import '../../providers/auth_provider.dart';

class BackendDebugScreen extends ConsumerStatefulWidget {
  const BackendDebugScreen({super.key});

  @override
  ConsumerState<BackendDebugScreen> createState() => _BackendDebugScreenState();
}

class _BackendDebugScreenState extends ConsumerState<BackendDebugScreen> {
  final List<_LogEntry> _logs = [];
  bool _isLoading = false;
  Map<String, dynamic>? _serverInfo;

  @override
  void initState() {
    super.initState();
    // Auto-check connection on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.insert(0, _LogEntry(
        message: message,
        timestamp: DateTime.now(),
        isError: isError,
      ));
      // Keep only last 100 logs
      if (_logs.length > 100) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    _addLog('Checking server connection...');

    try {
      final result = await BackendService.instance.checkStatus();
      
      if (result.isSuccess) {
        _addLog('✓ Server connected');
        _addLog('Response: ${result.data}');
        
        // Get server info
        final infoResult = await BackendService.instance.getServerInfo();
        if (infoResult.isSuccess) {
          setState(() => _serverInfo = infoResult.data);
          _addLog('Server info: ${infoResult.data}');
        }
      } else {
        _addLog('✗ Connection failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _addLog('✗ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetScores() async {
    setState(() => _isLoading = true);
    _addLog('Fetching scores from server...');

    try {
      final result = await BackendService.instance.getScores();
      
      if (result.isSuccess) {
        _addLog('✓ Got ${result.data?.length ?? 0} scores');
        for (final score in result.data ?? []) {
          _addLog('  - ${score.title} (id=${score.id}, version=${score.version})');
        }
      } else {
        _addLog('✗ Failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _addLog('✗ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetSetlists() async {
    setState(() => _isLoading = true);
    _addLog('Fetching setlists from server...');

    try {
      final result = await BackendService.instance.getSetlists();
      
      if (result.isSuccess) {
        _addLog('✓ Got ${result.data?.length ?? 0} setlists');
        for (final setlist in result.data ?? []) {
          _addLog('  - ${setlist.name} (id=${setlist.id})');
        }
      } else {
        _addLog('✗ Failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _addLog('✗ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSync() async {
    setState(() => _isLoading = true);
    _addLog('Triggering sync...');

    try {
      final result = await SyncService.instance.syncNow();
      
      if (result.success) {
        _addLog('✓ Sync completed');
        _addLog('  Uploaded: ${result.uploadedCount}');
        _addLog('  Downloaded: ${result.downloadedCount}');
        if (result.conflictCount > 0) {
          _addLog('  Conflicts: ${result.conflictCount}', isError: true);
        }
      } else {
        _addLog('✗ Sync failed: ${result.errorMessage}', isError: true);
      }
    } catch (e) {
      _addLog('✗ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAllServerData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete All Server Data'),
        content: const Text(
          'This will permanently delete ALL your data from the server:\n\n'
          '• All scores\n'
          '• All instrument scores\n'
          '• All annotations\n'
          '• All setlists\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    _addLog('⚠️ Deleting all server data...');

    try {
      final result = await BackendService.instance.deleteAllUserData();
      
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        _addLog('✓ Delete completed');
        _addLog('  Deleted scores: ${data.deletedScores}');
        _addLog('  Deleted instrument scores: ${data.deletedInstrumentScores}');
        _addLog('  Deleted annotations: ${data.deletedAnnotations}');
        _addLog('  Deleted setlists: ${data.deletedSetlists}');
        _addLog('  Deleted setlist scores: ${data.deletedSetlistScores}');
      } else {
        _addLog('✗ Delete failed: ${result.error}', isError: true);
      }
    } catch (e) {
      _addLog('✗ Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAuthInfo() {
    final backend = BackendService.instance;
    _addLog('=== Auth Info ===');
    _addLog('isLoggedIn: ${backend.isLoggedIn}');
    _addLog('userId: ${backend.userId}');
    _addLog('hasToken: ${backend.authToken != null}');
    if (backend.authToken != null) {
      final token = backend.authToken!;
      _addLog('token: ${token.length > 30 ? '${token.substring(0, 30)}...' : token}');
    }
    _addLog('status: ${backend.status}');
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  void _copyLogs() {
    final logText = _logs.map((e) => 
      '[${e.timestamp.toIso8601String()}] ${e.message}'
    ).join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authData = ref.watch(authProvider);
    final isLoggedIn = authData.isAuthenticated;

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
                          'Backend Debug',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(authData.backendStatus).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(authData.backendStatus),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              authData.backendStatus.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(authData.backendStatus),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Info Card
                  _buildSection(
                    title: 'Current User',
                    children: [
                      if (isLoggedIn && authData.user != null) ...[
                            _buildInfoRow('User ID', '${authData.user!.id}'),
                            _buildInfoRow('Username', authData.user!.username),
                            _buildInfoRow('Display Name', authData.user!.displayName ?? 'N/A'),
                            _buildInfoRow('Status', 'Logged In ✓'),
                          ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Not logged in. Please log in from the Cloud Sync settings to use debug features.',
                                  style: TextStyle(color: Colors.orange.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Connection Test
                  _buildSection(
                    title: 'Connection',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _checkConnection,
                              icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(AppIcons.refreshCw),
                              label: const Text('Test Connection'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue500,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showAuthInfo,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Auth Info'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // API Testing
                  _buildSection(
                    title: 'API Tests',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isLoggedIn && !_isLoading ? _testGetScores : null,
                            icon: const Icon(Icons.music_note),
                            label: const Text('Get Scores'),
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoggedIn && !_isLoading ? _testGetSetlists : null,
                            icon: const Icon(Icons.list),
                            label: const Text('Get Setlists'),
                          ),
                          ElevatedButton.icon(
                            onPressed: isLoggedIn && !_isLoading ? _testSync : null,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sync Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald500,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Danger Zone
                  _buildSection(
                    title: '⚠️ Danger Zone',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete All Server Data',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This will permanently delete all your scores, instrument scores, annotations, and setlists from the server.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoggedIn && !_isLoading ? _deleteAllServerData : null,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Delete All Server Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Server Info
                  if (_serverInfo != null)
                    _buildSection(
                      title: 'Server Info',
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _serverInfo.toString(),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Logs
                  _buildSection(
                    title: 'Logs',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(AppIcons.copy, size: 20),
                          onPressed: _copyLogs,
                          tooltip: 'Copy logs',
                        ),
                        IconButton(
                          icon: const Icon(AppIcons.delete, size: 20),
                          onPressed: _clearLogs,
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.gray900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet',
                                style: TextStyle(color: AppColors.gray500),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '[${_formatTime(log.timestamp)}] ${log.message}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: log.isError ? Colors.red.shade300 : Colors.green.shade300,
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BackendStatus status) {
    switch (status) {
      case BackendStatus.connected:
        return Colors.green;
      case BackendStatus.connecting:
        return Colors.orange;
      case BackendStatus.disconnected:
        return Colors.grey;
      case BackendStatus.error:
        return Colors.red;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}

class _LogEntry {
  final String message;
  final DateTime timestamp;
  final bool isError;

  _LogEntry({
    required this.message,
    required this.timestamp,
    this.isError = false,
  });
}