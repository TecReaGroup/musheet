import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state_provider.dart';
import '../core/core.dart';
import '../theme/app_colors.dart';

/// A widget that displays user avatar, using cached avatar from AuthProvider
/// for current user, or loading from server via RPC for other users
class UserAvatar extends ConsumerWidget {
  final int? userId;
  final String? avatarIdentifier; // "avatar:<userId>" or null
  final String displayName;
  final double size;

  const UserAvatar({
    super.key,
    this.userId,
    this.avatarIdentifier,
    required this.displayName,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final fontSize = size * 0.4;

    // Check if this is the current user - use cached avatar
    final isCurrentUser = userId != null && userId == authState.user?.id;

    if (isCurrentUser && authState.avatarBytes != null) {
      // Use cached avatar for current user
      return _AvatarContainer(
        size: size,
        hasImage: true,
        child: Image.memory(
          authState.avatarBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(initial, fontSize);
          },
        ),
      );
    }

    // For other users or when no cache, use the stateful version
    if (avatarIdentifier != null &&
        avatarIdentifier!.startsWith('avatar:') &&
        userId != null &&
        !isCurrentUser) {
      return _RemoteUserAvatar(
        userId: userId!,
        displayName: displayName,
        size: size,
      );
    }

    // No avatar - show placeholder
    return _AvatarContainer(
      size: size,
      hasImage: false,
      child: _buildPlaceholder(initial, fontSize),
    );
  }

  Widget _buildPlaceholder(String initial, double fontSize) {
    return Container(
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
          style: TextStyle(
            color: AppColors.avatarText,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Container for avatar with consistent styling
class _AvatarContainer extends StatelessWidget {
  final double size;
  final bool hasImage;
  final Widget child;

  const _AvatarContainer({
    required this.size,
    required this.hasImage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Stateful widget for loading avatar from server for non-current users
class _RemoteUserAvatar extends StatefulWidget {
  final int userId;
  final String displayName;
  final double size;

  const _RemoteUserAvatar({
    required this.userId,
    required this.displayName,
    required this.size,
  });

  @override
  State<_RemoteUserAvatar> createState() => _RemoteUserAvatarState();
}

class _RemoteUserAvatarState extends State<_RemoteUserAvatar> {
  Uint8List? _avatarBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(_RemoteUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load avatar using API client
      if (!ApiClient.isInitialized) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final result = await ApiClient.instance.getAvatar(widget.userId);
      
      if (mounted) {
        setState(() {
          _avatarBytes = result.isSuccess ? result.data : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : 'U';
    final fontSize = widget.size * 0.4;

    return _AvatarContainer(
      size: widget.size,
      hasImage: _avatarBytes != null,
      child: _buildContent(initial, fontSize),
    );
  }

  Widget _buildContent(String initial, double fontSize) {
    if (_avatarBytes != null) {
      return Image.memory(
        _avatarBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(initial, fontSize);
        },
      );
    }

    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.avatarGradientStart, AppColors.avatarGradientEnd],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.avatarText),
        ),
      );
    }

    return _buildPlaceholder(initial, fontSize);
  }

  Widget _buildPlaceholder(String initial, double fontSize) {
    return Container(
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
          style: TextStyle(
            color: AppColors.avatarText,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
