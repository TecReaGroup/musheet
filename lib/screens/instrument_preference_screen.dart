import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/instrument_score.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';
import 'library_screen.dart' show preferredInstrumentProvider;

class InstrumentPreferenceScreen extends ConsumerWidget {
  const InstrumentPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredInstrument = ref.watch(preferredInstrumentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.blue50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue400, AppColors.blue600],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        AppIcons.piano,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Instrument',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose your main instrument',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          AppIcons.close,
                          color: AppColors.gray400,
                          size: 22,
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // No preference option
                _buildInstrumentOption(
                  context: context,
                  ref: ref,
                  instrumentKey: null,
                  displayName: 'No Preference',
                  subtitle: 'Use default order',
                  isSelected: preferredInstrument == null,
                  icon: AppIcons.circleSlash,
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'INSTRUMENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Instrument options (excluding 'other')
                ...InstrumentType.values.where((type) => type != InstrumentType.other).map((type) {
                  final instrumentKey = type.name;
                  final displayName = type.name[0].toUpperCase() + type.name.substring(1);
                  final isSelected = preferredInstrument == instrumentKey;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: type == InstrumentType.bass
                        ? _buildInstrumentOptionWithWidget(
                            context: context,
                            ref: ref,
                            instrumentKey: instrumentKey,
                            displayName: displayName,
                            isSelected: isSelected,
                            iconWidget: AppIcons.bassGuitar(
                              size: 20,
                              color: isSelected ? Colors.white : AppColors.gray600,
                            ),
                          )
                        : _buildInstrumentOption(
                            context: context,
                            ref: ref,
                            instrumentKey: instrumentKey,
                            displayName: displayName,
                            isSelected: isSelected,
                            icon: _getInstrumentIcon(type),
                          ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentOption({
    required BuildContext context,
    required WidgetRef ref,
    required String? instrumentKey,
    required String displayName,
    String? subtitle,
    required bool isSelected,
    required IconData icon,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ref.read(preferredInstrumentProvider.notifier).setPreferredInstrument(instrumentKey);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.blue500 : AppColors.gray200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppColors.blue50 : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue500 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.gray600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? AppColors.blue600 : AppColors.gray900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.blue500 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  AppIcons.check,
                  size: 20,
                  color: AppColors.blue500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstrumentOptionWithWidget({
    required BuildContext context,
    required WidgetRef ref,
    required String? instrumentKey,
    required String displayName,
    String? subtitle,
    required bool isSelected,
    required Widget iconWidget,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ref.read(preferredInstrumentProvider.notifier).setPreferredInstrument(instrumentKey);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.blue500 : AppColors.gray200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppColors.blue50 : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue500 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: iconWidget,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? AppColors.blue600 : AppColors.gray900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.blue500 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  AppIcons.check,
                  size: 20,
                  color: AppColors.blue500,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInstrumentIcon(InstrumentType type) {
    switch (type) {
      case InstrumentType.vocal:
        return AppIcons.mic;
      case InstrumentType.keyboard:
        return AppIcons.keyboardMusic;
      case InstrumentType.drums:
        return AppIcons.drum;
      case InstrumentType.bass:
        return AppIcons.musicNote; // This won't be used, handled separately
      case InstrumentType.guitar:
        return AppIcons.guitar;
      case InstrumentType.other:
        return AppIcons.musicNote;
    }
  }
}