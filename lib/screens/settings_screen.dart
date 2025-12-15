import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import '../widgets/common_widgets.dart';
import '../models/instrument_score.dart';
import 'library_screen.dart' show preferredInstrumentProvider, teamEnabledProvider;
import '../router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Profile card section
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
                onTap: () {},
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
                onTap: () {},
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.notifications,
                label: 'Notifications',
                onTap: () {},
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
                onTap: () {},
                showDivider: true,
                isFirst: true,
              ),
              SettingsListItem(
                icon: AppIcons.infoOutline,
                label: 'About MuSheet',
                onTap: () {},
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
}