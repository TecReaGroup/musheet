/// Expandable Drawer Mixin - Shared drawer animation logic
///
/// Provides common drawer animation functionality for screens with
/// expandable side panels (LibraryScreen, TeamScreen).
library;

import 'package:flutter/material.dart';

/// Mixin for screens with expandable drawer functionality
mixin ExpandableDrawerMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  /// Whether the drawer is currently expanded
  bool get isDrawerExpanded => _isDrawerExpanded;
  bool _isDrawerExpanded = false;

  /// Animation controller for drawer
  late AnimationController drawerController;

  /// Curved animation for drawer
  late Animation<double> drawerAnimation;

  /// Initialize drawer animation - call in initState
  void initDrawerAnimation({
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOut,
  }) {
    drawerController = AnimationController(
      duration: duration,
      vsync: this,
    );
    drawerAnimation = CurvedAnimation(
      parent: drawerController,
      curve: curve,
    );
  }

  /// Dispose drawer animation - call in dispose
  void disposeDrawerAnimation() {
    drawerController.dispose();
  }

  /// Toggle drawer open/close state
  void toggleDrawer({FocusNode? focusNodeToUnfocus}) {
    setState(() {
      _isDrawerExpanded = !_isDrawerExpanded;
      if (_isDrawerExpanded) {
        drawerController.forward();
      } else {
        drawerController.reverse();
        focusNodeToUnfocus?.unfocus();
      }
    });
  }

  /// Open the drawer
  void openDrawer() {
    if (!_isDrawerExpanded) {
      setState(() {
        _isDrawerExpanded = true;
        drawerController.forward();
      });
    }
  }

  /// Close the drawer
  void closeDrawer({FocusNode? focusNodeToUnfocus}) {
    if (_isDrawerExpanded) {
      setState(() {
        _isDrawerExpanded = false;
        drawerController.reverse();
        focusNodeToUnfocus?.unfocus();
      });
    }
  }
}
