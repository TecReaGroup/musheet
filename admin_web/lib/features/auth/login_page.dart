import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/admin_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(adminAuthProvider.notifier);

    if (_isSignUpMode) {
      await authNotifier.register(
        _usernameController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
      );
    } else {
      await authNotifier.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final needsRegistration = ref.watch(needsRegistrationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF), Color(0xFFECFDF5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 860;

                    final intro = _LoginIntroPanel(isSignUpMode: _isSignUpMode);
                    final form = _LoginFormCard(
                      formKey: _formKey,
                      authState: authState,
                      needsRegistration: needsRegistration,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      displayNameController: _displayNameController,
                      isPasswordVisible: _isPasswordVisible,
                      isSignUpMode: _isSignUpMode,
                      onTogglePassword: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      onToggleMode: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                        });
                        ref.read(adminAuthProvider.notifier).clearError();
                      },
                      onSubmit: _handleSubmit,
                    );

                    if (stacked) {
                      return Column(
                        children: [
                          intro,
                          const SizedBox(height: 20),
                          form,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: intro),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: form),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginIntroPanel extends StatelessWidget {
  final bool isSignUpMode;

  const _LoginIntroPanel({required this.isSignUpMode});

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(28),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminAppWordmark(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Text(
              isSignUpMode ? 'First-time admin setup' : 'Secure admin access',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.indigo600,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'A focused control room for MuSheet operations.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.gray900,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Manage users, teams, and platform health in a workspace that matches the main app: bright surfaces, clear spacing, and low-noise hierarchy.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.gray600,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                const AdminUserAvatar(name: 'MuSheet Admin', size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protected workspace',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Administrator-only access with a lighter, product-aligned interface.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.gray500,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              AdminMetricPill(
                icon: LucideIcons.shieldCheck,
                label: 'Role',
                value: 'Admin',
              ),
              AdminMetricPill(
                icon: LucideIcons.server,
                label: 'Runtime',
                value: 'Serverpod',
                accent: AppColors.emerald600,
              ),
              AdminMetricPill(
                icon: LucideIcons.monitorSmartphone,
                label: 'UX',
                value: 'Unified',
                accent: AppColors.purple600,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _FeatureRow(
            icon: LucideIcons.layoutDashboard,
            title: 'See platform status quickly',
            subtitle: 'Start from a single overview of users, teams, content, and service health.',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: LucideIcons.palette,
            title: 'Stay visually consistent',
            subtitle: 'The admin side follows the same color, spacing, and icon system as the app.',
          ),
          const SizedBox(height: 14),
          _FeatureRow(
            icon: LucideIcons.lock,
            title: 'Keep access controlled',
            subtitle: 'Only administrator accounts can enter this workspace and operate platform-level actions.',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gray800, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gray900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray600,
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AdminAuthState authState;
  final AsyncValue<bool> needsRegistration;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final bool isPasswordVisible;
  final bool isSignUpMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleMode;
  final Future<void> Function() onSubmit;

  const _LoginFormCard({
    required this.formKey,
    required this.authState,
    required this.needsRegistration,
    required this.usernameController,
    required this.passwordController,
    required this.displayNameController,
    required this.isPasswordVisible,
    required this.isSignUpMode,
    required this.onTogglePassword,
    required this.onToggleMode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(28),
      radius: 22,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AdminUserAvatar(
                  name: isSignUpMode ? 'New Admin' : 'MuSheet Admin',
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSignUpMode ? 'Create account' : 'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.gray900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSignUpMode
                            ? 'Register the first administrator account for this workspace.'
                            : 'Sign in with administrator credentials to continue.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isSignUpMode)
              needsRegistration.when(
                data: (needsReg) => AdminInlineMessage(
                  icon: needsReg ? LucideIcons.badgeInfo : LucideIcons.triangleAlert,
                  message: needsReg
                      ? 'The first registered account will automatically become admin.'
                      : 'This workspace only accepts accounts that already have administrator access.',
                  color: needsReg ? AppColors.indigo600 : AppColors.yellow600,
                  backgroundColor:
                      needsReg ? AppColors.blue50 : AppColors.yellow50,
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            if (isSignUpMode) const SizedBox(height: 16),
            _LabeledField(
              label: 'Username',
              child: TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter username',
                  prefixIcon: Icon(LucideIcons.user, size: 18, color: AppColors.indigo600),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (isSignUpMode) ...[
              _LabeledField(
                label: 'Display name',
                child: TextFormField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    hintText: 'Optional name shown in UI',
                    prefixIcon: Icon(LucideIcons.badge, size: 18, color: AppColors.indigo600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _LabeledField(
              label: 'Password',
              child: TextFormField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText:
                      isSignUpMode ? 'Minimum 6 characters' : 'Enter password',
                  prefixIcon: const Icon(
                    LucideIcons.lock,
                    size: 18,
                    color: AppColors.indigo600,
                  ),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      isPasswordVisible
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                      size: 18,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (isSignUpMode && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              AdminInlineMessage(
                icon: LucideIcons.circleAlert,
                message: authState.error!,
                color: AppColors.red600,
                backgroundColor: AppColors.red50,
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      size: 18,
                      color: AppColors.blue600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignUpMode ? 'Setup note' : 'Security note',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.gray900,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignUpMode
                              ? 'Use a strong password now. This account controls users, teams, and platform-level actions.'
                              : 'This session grants access to user, team, and system administration actions.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gray600,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: authState.isLoading ? null : onSubmit,
                icon: authState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        isSignUpMode
                            ? LucideIcons.userPlus
                            : LucideIcons.logIn,
                        size: 18,
                      ),
                label: Text(isSignUpMode ? 'Create account' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSignUpMode
                      ? 'Already have an account?'
                      : 'Need an account?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
                TextButton(
                  onPressed: onToggleMode,
                  child: Text(isSignUpMode ? 'Sign in' : 'Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.gray700,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
