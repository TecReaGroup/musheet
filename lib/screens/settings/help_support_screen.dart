import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../utils/icon_mappings.dart';
import '../../router/app_router.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // Fixed header with back button
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
                          'Help & Support',
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
              child: Builder(
                builder: (context) => ListView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
                  ),
                  children: [
                    _buildHelpItem(
                      icon: AppIcons.bookOpen,
                      title: 'Getting Started',
                      description: 'Learn the basics of using MuSheet',
                      onTap: () {
                        // TODO: Open getting started guide
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      icon: AppIcons.helpOutline,
                      title: 'FAQ',
                      description: 'Frequently asked questions',
                      onTap: () {
                        // TODO: Open FAQ
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      icon: AppIcons.mail,
                      title: 'Contact Us',
                      description: 'Get in touch with our support team',
                      onTap: () {
                        // TODO: Open contact form
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      icon: AppIcons.bug,
                      title: 'Report a Bug',
                      description: 'Help us improve by reporting issues',
                      onTap: () {
                        // TODO: Open bug report form
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      icon: AppIcons.lightbulb,
                      title: 'Feature Request',
                      description: 'Suggest new features or improvements',
                      onTap: () {
                        // TODO: Open feature request form
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: 20,
                color: AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
