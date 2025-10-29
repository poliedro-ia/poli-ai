import 'package:flutter/material.dart';

PageRoute<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, anim, sec, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0, .08),
        end: Offset.zero,
      ).animate(curve);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
