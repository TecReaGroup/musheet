/// Sort Bar Widget - Reusable sort bar with search and sort controls
///
/// Used in both LibraryScreen and TeamScreen for consistent sorting UI.
library;

import 'package:flutter/material.dart';

import '../models/sort_state.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mappings.dart';

/// Sort bar with search field and sort button
class SortBar extends StatelessWidget {
  /// Current sort state
  final SortState sortState;

  /// Callback when sort type is selected
  final void Function(SortType) onSortChanged;

  /// Search text controller
  final TextEditingController searchController;

  /// Search focus node
  final FocusNode searchFocusNode;

  /// Current search query
  final String searchQuery;

  /// Callback when search query changes
  final void Function(String) onSearchChanged;

  /// Callback when search is cleared
  final VoidCallback onSearchCleared;

  /// Search placeholder text
  final String searchHint;

  const SortBar({
    super.key,
    required this.sortState,
    required this.onSortChanged,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    this.searchHint = 'Search...',
  });

  String _getSortLabel(SortType type) {
    switch (type) {
      case SortType.recentCreated:
        return 'Added';
      case SortType.alphabetical:
        return 'A-Z';
      case SortType.recentOpened:
        return 'Opened';
    }
  }

  IconData _getSortIcon(SortType type) {
    switch (type) {
      case SortType.recentCreated:
        return AppIcons.clock;
      case SortType.alphabetical:
        return AppIcons.alphabetical;
      case SortType.recentOpened:
        return AppIcons.calendarClock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          // Search box
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                style: const TextStyle(fontSize: 13, color: AppColors.gray700),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
                  prefixIcon: const Icon(AppIcons.search, size: 16, color: AppColors.gray400),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  suffixIcon: searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            onSearchCleared();
                          },
                          child: const Icon(AppIcons.close, size: 14, color: AppColors.gray400),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 32),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort button
          _SortButton(
            sortState: sortState,
            onSortChanged: onSortChanged,
            getSortLabel: _getSortLabel,
            getSortIcon: _getSortIcon,
            onMenuOpened: () => searchFocusNode.unfocus(),
          ),
        ],
      ),
    );
  }
}

/// Sort button with popup menu
class _SortButton extends StatelessWidget {
  final SortState sortState;
  final void Function(SortType) onSortChanged;
  final String Function(SortType) getSortLabel;
  final IconData Function(SortType) getSortIcon;
  final VoidCallback? onMenuOpened;

  const _SortButton({
    required this.sortState,
    required this.onSortChanged,
    required this.getSortLabel,
    required this.getSortIcon,
    this.onMenuOpened,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortType>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 130),
      tooltip: '',
      splashRadius: 0,
      onOpened: onMenuOpened,
      onSelected: onSortChanged,
      onCanceled: onMenuOpened,
      itemBuilder: (context) => [
        _buildSortMenuItem(SortType.recentCreated, 'Added', AppIcons.clock),
        _buildSortMenuItem(SortType.alphabetical, 'A-Z', AppIcons.alphabetical),
        _buildSortMenuItem(SortType.recentOpened, 'Opened', AppIcons.calendarClock),
      ],
      child: Material(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.gray200,
          highlightColor: AppColors.gray100,
          onTap: null,
          child: Container(
            width: 130,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(getSortIcon(sortState.type), size: 16, color: AppColors.gray400),
                const SizedBox(width: 6),
                Text(
                  getSortLabel(sortState.type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  sortState.ascending ? AppIcons.arrowUp : AppIcons.arrowDown,
                  size: 14,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<SortType> _buildSortMenuItem(SortType type, String label, IconData icon) {
    final isSelected = sortState.type == type;
    return PopupMenuItem<SortType>(
      value: type,
      mouseCursor: SystemMouseCursors.click,
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.blue600 : AppColors.gray500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.blue600 : AppColors.gray700,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                sortState.ascending ? AppIcons.arrowUp : AppIcons.arrowDown,
                size: 16,
                color: AppColors.blue600,
              ),
          ],
        ),
      ),
    );
  }
}
