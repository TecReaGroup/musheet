import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Builder(
        builder: (context) => ListView(
          // Remove default top padding, we handle it manually in the header container
          // Add bottom padding for bottom navigation bar
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight),
          children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            // Add top safe area padding
            padding: EdgeInsets.fromLTRB(16, 24 + MediaQuery.of(context).padding.top, 16, 24),
            child: const Text(
              'Settings',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.gray700),
            ),
          ),
          
          // Profile card section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.blue500, Color(0xFF9333EA)]),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Center(
                            child: Text('A', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alex Chen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('alex.chen@music.com', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
                              SizedBox(height: 4),
                              Text('Premium Member', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ],
                          ),
                        ),
                        const Icon(AppIcons.chevronRight, color: AppColors.gray400),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('PERFORMANCE', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: _SettingsItem(
                icon: AppIcons.bluetooth,
                label: 'Bluetooth Devices',
                onTap: () {},
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('SYNC & STORAGE', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: AppIcons.cloud,
                    label: 'Cloud Sync',
                    onTap: () {},
                    showDivider: true,
                  ),
                  _SettingsItem(
                    icon: AppIcons.notifications,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('ABOUT', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Column(
                children: [
                  _SettingsItem(
                    icon: AppIcons.helpOutline,
                    label: 'Help & Support',
                    onTap: () {},
                    showDivider: true,
                  ),
                  _SettingsItem(
                    icon: AppIcons.infoOutline,
                    label: 'About MuSheet',
                    onTap: () {},
                  ),
                ],
              ),
            ),
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
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.gray600),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label)),
                  const Icon(AppIcons.chevronRight, size: 20, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.gray200),
      ],
    );
  }
}