import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../providers/auth_provider.dart';
import '../../services/backend_service.dart';
import '../../router/app_router.dart';
import 'settings_sub_screen.dart';
import 'avatar_crop_screen.dart';

/// Profile screen showing user info and logout option
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final authData = ref.watch(authProvider);
    final user = authData.user;

    // If not authenticated, redirect to login
    if (!authData.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.login);
      });
      return const SizedBox.shrink();
    }

    final displayName = user?.displayName ?? 'User';
    final username = user?.username ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    // Use cached avatar from AuthProvider
    final avatarBytes = authData.avatarBytes;

    return SettingsSubScreen(
      title: 'Profile',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Tappable Avatar
                  GestureDetector(
                    onTap: () => _showAvatarOptions(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: (avatarBytes == null)
                                ? const LinearGradient(
                                    colors: [AppColors.blue500, Color(0xFF9333EA)],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatarBytes != null
                              ? Image.memory(
                                  avatarBytes,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildAvatarPlaceholder(initial);
                                  },
                                )
                              : _buildAvatarPlaceholder(initial),
                        ),
                        // Edit indicator
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.edit,
                              size: 16,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tappable Display name
                  GestureDetector(
                    onTap: () => _showEditDisplayNameDialog(context, displayName),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Placeholder for symmetry
                        const SizedBox(width: 26),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          AppIcons.edit,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Username (not editable)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Connection status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: authData.isConnected
                              ? AppColors.emerald500
                              : AppColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        authData.isConnected ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 14,
                          color: authData.isConnected
                              ? AppColors.emerald600
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Profile options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: [
                        // Change Password
                        _buildOptionTile(
                          icon: AppIcons.rotateCcwKey,
                          label: 'Change Password',
                          onTap: () => _showChangePasswordDialog(context),
                          showDivider: true,
                        ),
                        // Cloud Sync Settings
                        _buildOptionTile(
                          icon: AppIcons.cloud,
                          label: 'Cloud Sync Settings',
                          onTap: () => context.go(AppRoutes.cloudSync),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout button at bottom
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSignOutConfirmation(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red500,
                    side: const BorderSide(color: AppColors.red300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(AppIcons.close, size: 20),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: AppColors.gray600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                  const Icon(
                    AppIcons.chevronRight,
                    size: 20,
                    color: AppColors.gray400,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 50, color: AppColors.gray200),
      ],
    );
  }

  /// Build avatar placeholder with initial
  Widget _buildAvatarPlaceholder(String initial) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue500, Color(0xFF9333EA)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Show avatar edit options
  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
              leading: const Icon(AppIcons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Pick image and upload as avatar
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      // Navigate to custom crop screen
      final Uint8List? croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (context) => AvatarCropScreen(
            imageFile: File(pickedFile.path),
          ),
        ),
      );

      if (croppedBytes == null) return;

      setState(() => _isUpdating = true);

      final result = await BackendService.instance.uploadAvatar(
        imageBytes: croppedBytes,
        fileName: 'avatar.png',
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Update cached avatar in AuthProvider
        ref.read(authProvider.notifier).updateCachedAvatar(croppedBytes);
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: ${result.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Show dialog to edit display name
  void _showEditDisplayNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                Navigator.pop(context);
                await _updateDisplayName(newName);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Update display name on server
  Future<void> _updateDisplayName(String newName) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final result = await BackendService.instance.updateProfile(
        displayName: newName,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Refresh profile to get updated data
        await ref.read(authProvider.notifier).refreshProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${result.error}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Show dialog to change password
  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final result =
                            await BackendService.instance.changePassword(
                          oldPassword: oldPasswordController.text,
                          newPassword: newPasswordController.text,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.isSuccess
                                  ? 'Password changed successfully'
                                  : 'Failed: ${result.error}',
                            ),
                            backgroundColor: result.isSuccess
                                ? AppColors.emerald500
                                : AppColors.red500,
                          ),
                        );
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sign out confirmation dialog with pending changes warning
  Future<void> _showSignOutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check for pending changes
    final pendingCount =
        await ref.read(authProvider.notifier).getPendingChangesCount();

    if (!context.mounted) return;

    if (pendingCount > 0) {
      // Show warning dialog with pending changes count
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsynced Data'),
          content: Text(
            'You have $pendingCount unsynced changes that will be lost if you sign out.\n\n'
            'Are you sure you want to sign out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red500),
              child: const Text('Sign Out Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    } else {
      // No pending changes, just confirm
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'All local data will be deleted. Are you sure you want to sign out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.red500),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    }

    // Perform logout
    await ref.read(authProvider.notifier).logout();

    if (context.mounted) {
      // Navigate back to settings
      context.go(AppRoutes.settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );
    }
  }
}
