import 'package:flutter/material.dart';

/// Custom page transitions for the MuSheet app
/// Provides smooth, consistent animations between screens

/// Fade transition for smooth page changes
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Slide transition from bottom (for modals and detail screens)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: tween.animate(curvedAnimation),
              child: child,
            );
          },
        );
}

/// Slide transition from right (for navigation)
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideRightPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: tween.animate(curvedAnimation),
              child: child,
            );
          },
        );
}

/// Scale and fade transition (for emphasis)
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScaleFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
        );
}

/// Shared axis transition (Material Design 3 style)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
        );
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

class _SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const _SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outgoing page
        SlideTransition(
          position: _getOutgoingOffset(),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
              ),
            ),
            child: Container(),
          ),
        ),
        // Incoming page
        SlideTransition(
          position: _getIncomingOffset(),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Animation<Offset> _getIncomingOffset() {
    final tween = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    );
    return tween.animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Animation<Offset> _getOutgoingOffset() {
    final tween = Tween<Offset>(
      begin: Offset.zero,
      end: _getEndOffset(),
    );
    return tween.animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      ),
    );
  }

  Offset _getBeginOffset() {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return const Offset(0.3, 0.0);
      case SharedAxisTransitionType.vertical:
        return const Offset(0.0, 0.3);
      case SharedAxisTransitionType.scaled:
        return Offset.zero;
    }
  }

  Offset _getEndOffset() {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return const Offset(-0.3, 0.0);
      case SharedAxisTransitionType.vertical:
        return const Offset(0.0, -0.3);
      case SharedAxisTransitionType.scaled:
        return Offset.zero;
    }
  }
}

/// Helper extension for easy navigation with transitions
extension NavigationExtensions on BuildContext {
  /// Navigate with fade transition
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadePageRoute(page: page));
  }

  /// Navigate with slide up transition
  Future<T?> pushSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpPageRoute(page: page));
  }

  /// Navigate with slide right transition
  Future<T?> pushSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideRightPageRoute(page: page));
  }

  /// Navigate with scale fade transition
  Future<T?> pushScaleFade<T>(Widget page) {
    return Navigator.of(this).push<T>(ScaleFadePageRoute(page: page));
  }

  /// Navigate with shared axis transition
  Future<T?> pushSharedAxis<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return Navigator.of(this).push<T>(
      SharedAxisPageRoute(page: page, transitionType: type),
    );
  }
}