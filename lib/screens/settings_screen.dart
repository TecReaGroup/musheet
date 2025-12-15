import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../models/instrument_score.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_providers.dart';
import '../services/backend_service.dart';
import 'library_screen.dart' show preferredInstrumentProvider, teamEnabledProvider;
import '../router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authData = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Fixed header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            // Add top safe area padding
            padding: EdgeInsets.fromLTRB(16, 16 + MediaQuery.of(context).padding.top, 16, 24),
            child: const Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              // Add bottom padding for bottom navigation bar
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
              children: [
          // Profile card section - shows login button or user profile
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (authData.isAuthenticated) {
                      // Show user profile options
                      _showUserProfileSheet(context, ref, authData);
                    } else {
                      // Show login dialog
                      _showLoginDialog(context, ref);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: authData.isAuthenticated
                      ? _buildLoggedInProfile(authData)
                      : _buildLoginPrompt(),
                  ),
                ),
              ),
            ),
          ),

          SettingsGroup(
            title: 'PREFERENCES',
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final preferredInstrument = ref.watch(preferredInstrumentProvider);
                  String displayText = 'Not set';
                  if (preferredInstrument != null) {
                    // Try to find the instrument type
                    final instrumentType = InstrumentType.values.firstWhere(
                      (type) => type.name == preferredInstrument,
                      orElse: () => InstrumentType.other,
                    );
                    displayText = instrumentType.name[0].toUpperCase() + instrumentType.name.substring(1);
                  }
                  
                  return SettingsListItem(
                    icon: AppIcons.piano,
                    label: 'Preferred Instrument',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(AppIcons.chevronRight, size: 20, color: AppColors.gray400),
                      ],
                    ),
                    onTap: () {
                      AppNavigation.navigateToInstrumentPreference(context);
                    },
                    showDivider: true,
                    isFirst: true,
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final teamEnabled = ref.watch(teamEnabledProvider);
                  
                  return SettingsListItem(
                    icon: AppIcons.people,
                    label: 'Enable Team',
                    trailing: GestureDetector(
                      onTap: () {
                        ref.read(teamEnabledProvider.notifier).setTeamEnabled(!teamEnabled);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: teamEnabled ? AppColors.blue500 : AppColors.gray300,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: teamEnabled ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      ref.read(teamEnabledProvider.notifier).setTeamEnabled(!teamEnabled);
                    },
                    showDivider: true,
                  );
                },
              ),
              SettingsListItem(
                icon: AppIcons.bluetooth,
                label: 'Bluetooth Devices',
                onTap: () => context.go(AppRoutes.bluetoothDevices),
                isLast: true,
              ),
            ],
          ),

          SettingsGroup(
            title: 'SYNC & STORAGE',
            children: [
              SettingsListItem(
                icon: AppIcons.cloud,
                label: 'Cloud Sync',
                onTap: () => context.go(AppRoutes.cloudSync),
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.notifications,
                label: 'Notifications',
                onTap: () => context.go(AppRoutes.notifications),
                isLast: true,
              ),
            ],
          ),

          SettingsGroup(
            title: 'ABOUT',
            children: [
              SettingsListItem(
                icon: AppIcons.helpOutline,
                label: 'Help & Support',
                onTap: () => context.go(AppRoutes.helpSupport),
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.infoOutline,
                label: 'About MuSheet',
                onTap: () => context.go(AppRoutes.about),
                showDivider: true,
              ),
              SettingsListItem(
                icon: AppIcons.bug,
                label: 'Backend Debug',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DEV',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue500,
                    ),
                  ),
                ),
                onTap: () => context.go(AppRoutes.backendDebug),
                isLast: true,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Text('MuSheet', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                SizedBox(height: 8),
                Text(
                  'Digital score management for musicians',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Center(
            child: Icon(AppIcons.person, color: AppColors.gray400, size: 32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in to sync',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect to server to sync your music',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue500,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInProfile(AuthData authData) {
    final user = authData.user;
    final displayName = user?.displayName ?? 'User';
    final username = user?.username ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.blue500, Color(0xFF9333EA)]),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 4),
              Text(username, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: authData.isConnected ? AppColors.emerald500 : AppColors.gray400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    authData.isConnected ? 'Connected' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: authData.isConnected ? AppColors.emerald600 : AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Icon(AppIcons.chevronRight, color: AppColors.gray400),
      ],
    );
  }

  void _showUserProfileSheet(BuildContext context, WidgetRef ref, AuthData authData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(AppIcons.refreshCw),
              title: const Text('Sync Now'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing...')),
                );
              },
            ),
            ListTile(
              leading: Icon(AppIcons.cloud, color: AppColors.gray600),
              title: const Text('Cloud Sync Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.cloudSync);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(AppIcons.close, color: AppColors.red500),
              title: Text('Sign Out', style: TextStyle(color: AppColors.red500)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Login dialog with server URL and credentials
class LoginDialog extends ConsumerStatefulWidget {
  const LoginDialog({super.key});

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = 'http://localhost:8080';
    _loadSavedServerUrl();
  }

  Future<void> _loadSavedServerUrl() async {
    final prefs = ref.read(preferencesProvider);
    if (prefs != null) {
      final savedUrl = prefs.getServerUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        setState(() {
          _serverUrlController.text = savedUrl;
        });
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a server URL');
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _error = null;
    });

    try {
      final prefs = ref.read(preferencesProvider);
      await prefs?.setServerUrl(url);
      BackendService.initialize(baseUrl: url);

      final result = await BackendService.instance.checkStatus();

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to server!'),
              backgroundColor: AppColors.emerald500,
            ),
          );
        } else {
          setState(() => _error = 'Connection failed: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isNotEmpty) {
      final prefs = ref.read(preferencesProvider);
      await prefs?.setServerUrl(serverUrl);
      BackendService.initialize(baseUrl: serverUrl);
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool success;
      if (_isLogin) {
        success = await ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        success = await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Logged in successfully!' : 'Account created!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
      } else if (mounted) {
        final authError = ref.read(authProvider).error;
        setState(() => _error = authError ?? 'Authentication failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Server URL
                TextFormField(
                  controller: _serverUrlController,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'http://localhost:8080',
                    prefixIcon: const Icon(AppIcons.globe),
                    suffixIcon: IconButton(
                      icon: _isTestingConnection
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(AppIcons.refreshCw, size: 20),
                      onPressed: _isTestingConnection ? null : _testConnection,
                      tooltip: 'Test connection',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.red50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red200),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red600, fontSize: 13),
                    ),
                  ),

                // Display name (register only)
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: const Icon(AppIcons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(AppIcons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(AppIcons.close),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? AppIcons.close : AppIcons.check),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                ),
                const SizedBox(height: 12),

                // Toggle login/register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    });
                  },
                  child: Text(
                    _isLogin
                      ? "Don't have an account? Create one"
                      : 'Already have an account? Sign in',
                    style: const TextStyle(color: AppColors.blue500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}