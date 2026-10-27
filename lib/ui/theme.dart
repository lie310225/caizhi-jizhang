import 'package:flutter/material.dart';

/// 绿色金融主题（与创意方案视觉一致），Material 3
ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
