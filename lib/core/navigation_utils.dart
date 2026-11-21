import 'package:flutter/material.dart';

/// Centralized Neumorphic Page Route transition with subtle slide and fade.
PageRoute<T> neuRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 280),
  );
}
