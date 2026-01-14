import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../providers/auth_state_provider.dart';
import '../../core/core.dart';
import '../../router/app_router.dart';
import '../../widgets/common_widgets.dart';
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
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // If not authenticated, redirect to login
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.login);
      });
      return const SizedBox.shrink();
    }

    final displayName = user?.displayName ?? 'User';
    final username = user?.username ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    // Use cached avatar from AuthState
    final avatarBytes = authState.avatarBytes;

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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.avatarGradientStart,
                                      AppColors.avatarGradientEnd,
                                    ],
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
                    onTap: () =>
                        _showEditDisplayNameDialog(context, displayName),
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
                          color: authState.isConnected
                              ? AppColors.emerald500
                              : AppColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        authState.isConnected ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 14,
                          color: authState.isConnected
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.avatarGradientStart, AppColors.avatarGradientEnd],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.avatarText,
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

      // Navigate to custom crop screen (use root navigator to hide bottom nav)
      final Uint8List? croppedBytes = await Navigator.of(context, rootNavigator: true)
          .push<Uint8List>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => AvatarCropScreen(
                imageFile: File(pickedFile.path),
              ),
            ),
          );

      if (croppedBytes == null) return;

      setState(() => _isUpdating = true);

      // Upload avatar using API client
      final authState = ref.read(authStateProvider);
      if (authState.user == null || !ApiClient.isInitialized) {
        if (!mounted) return;
        AppToast.warning(context, 'Not logged in');
        return;
      }

      final result = await ApiClient.instance.uploadAvatar(
        userId: authState.user!.id,
        imageBytes: croppedBytes,
        fileName: 'avatar.jpg',
      );

      if (!mounted) return;
      if (result.isSuccess) {
        // Refresh auth state to get new avatar URL
        await ref.read(authStateProvider.notifier).refreshProfile();
        if (!mounted) return;
        AppToast.success(context, 'Avatar updated!');
      } else {
        AppToast.error(
          context,
          'Failed: ${result.error?.message ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: $e');
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
      final authState = ref.read(authStateProvider);
      if (authState.user == null || !ApiClient.isInitialized) {
        if (!mounted) return;
        AppToast.warning(context, 'Not logged in');
        return;
      }

      final result = await ApiClient.instance.updateProfile(
        userId: authState.user!.id,
        displayName: newName,
      );

      if (!mounted) return;
      if (result.isSuccess) {
        await ref.read(authStateProvider.notifier).refreshProfile();
        if (!mounted) return;
        AppToast.success(context, 'Profile updated!');
      } else {
        AppToast.error(
          context,
          'Failed: ${result.error?.message ?? 'Unknown error'}',
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
    final formKey = GlobalKey<FormState>();

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock icon header
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.blue50, AppColors.blue100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          AppIcons.rotateCcwKey,
                          size: 28,
                          color: AppColors.blue550,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current Password
                      TextFormField(
                        controller: oldPasswordController,
                        style: const TextStyle(color: AppColors.gray500),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: const TextStyle(color: AppColors.gray400),
                          prefixIcon: const Icon(
                            AppIcons.rotateCcwKey,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.blue400,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      TextFormField(
                        controller: newPasswordController,
                        style: const TextStyle(color: AppColors.gray500),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(color: AppColors.gray400),
                          prefixIcon: const Icon(
                            LucideIcons.keyRound,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gray200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.blue400,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.gray200),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Change button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      final authState =
                                          ref.read(authStateProvider);
                                      if (authState.user == null ||
                                          !ApiClient.isInitialized) {
                                        Navigator.pop(dialogContext);
                                        AppToast.warning(
                                          dialogContext,
                                          'Not logged in',
                                        );
                                        return;
                                      }

                                      setDialogState(() => isSubmitting = true);

                                      final result =
                                          await ApiClient.instance.changePassword(
                                        userId: authState.user!.id,
                                        oldPassword: oldPasswordController.text,
                                        newPassword: newPasswordController.text,
                                      );

                                      if (!mounted) return;
                                      if (!dialogContext.mounted) return;

                                      Navigator.pop(dialogContext);

                                      if (result.isSuccess &&
                                          result.data == true) {
                                        AppToast.success(
                                          this.context,
                                          'Password changed!',
                                        );
                                      } else {
                                        AppToast.error(
                                          this.context,
                                          'Failed: ${result.error?.message ?? 'Check your current password'}',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
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
                                  : const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show sign out confirmation dialog with pending changes warning
  Future<void> _showSignOutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check for pending changes - for now, just assume 0
    const pendingCount = 0;

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
    await ref.read(authStateProvider.notifier).logout();

    if (context.mounted) {
      // Navigate back to settings
      context.go(AppRoutes.settings);
      AppToast.success(context, 'Signed out successfully');
    }
  }
}
