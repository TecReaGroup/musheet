import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/core_providers.dart';
import '../../core/core.dart';
import '../../router/app_router.dart';
import '../../widgets/common_widgets.dart';
import 'settings_sub_screen.dart';

/// Login screen as a sub-screen under settings
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
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
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('backend_server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        _serverUrlController.text = savedUrl;
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_server_url', url);
      ApiClient.initialize(baseUrl: url);

      // Test server connectivity using health check endpoint
      final healthResult = await ApiClient.instance.checkHealth();
      if (!mounted) return;

      if (healthResult.isSuccess) {
        AppToast.success(context, 'Server connected successfully');
      } else {
        AppToast.warning(
          context,
          'Server unreachable: ${healthResult.error?.message ?? 'Connection failed'}',
        );
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backend_server_url', serverUrl);
      ApiClient.initialize(baseUrl: serverUrl);
      // Invalidate providers to pick up new ApiClient
      ref.invalidate(apiClientProvider);
      ref.invalidate(authRepositoryProvider);
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool success;
      if (_isLogin) {
        success = await ref
            .read(authStateProvider.notifier)
            .login(
              username: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            );
      } else {
        final username = _usernameController.text.trim();
        success = await ref
            .read(authStateProvider.notifier)
            .register(
              username: username,
              password: _passwordController.text.trim(),
              displayName: username,
            );
      }

      if (success && mounted) {
        // Navigate back to settings
        context.go(AppRoutes.settings);
        AppToast.success(
          context,
          _isLogin ? 'Logged in successfully!' : 'Account created!',
        );

        // Trigger sync after successful login
        try {
          final syncCoordinator = ref.read(syncCoordinatorProvider);
          if (syncCoordinator != null) {
            await syncCoordinator.syncNow();
          }
        } catch (_) {
          // Sync trigger failed, ignore
        }
      } else if (mounted) {
        final authError = ref.read(authStateProvider).error;
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
    return SettingsSubScreen(
      title: _isLogin ? 'Sign In' : 'Create Account',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    style: const TextStyle(
                      color: AppColors.red600,
                      fontSize: 13,
                    ),
                  ),
                ),

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
                    icon: Icon(
                      _obscurePassword ? AppIcons.close : AppIcons.check,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
    );
  }
}
