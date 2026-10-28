import 'package:flutter/material.dart';

/// 深墨绿财务主题（Material 3），seed #1B5E20
ThemeData buildTheme() {
  const seed = Color(0xFF1B5E20);
  final light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: light,
    scaffoldBackgroundColor: light.surface,
    // ------------------------------------------------------------------
    // AppBar：M3 标准样式
    // ------------------------------------------------------------------
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: light.surface,
      foregroundColor: light.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: light.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    // ------------------------------------------------------------------
    // Card：圆角 12、elevation 1
    // ------------------------------------------------------------------
    cardTheme: CardThemeData(
      color: light.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    ),
    // ------------------------------------------------------------------
    // 底部导航：M3 指示器 + 选中态
    // ------------------------------------------------------------------
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light.surface,
      indicatorColor: light.secondaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: light.onSecondaryContainer, size: 24);
        }
        return IconThemeData(color: light.onSurfaceVariant, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: light.onSurface, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: light.onSurfaceVariant);
      }),
    ),
    // ------------------------------------------------------------------
    // 输入框：统一圆角 + 选中高亮
    // ------------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: light.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: light.primary, width: 1.5),
      ),
    ),
    // ------------------------------------------------------------------
    // FilledButton / TextButton
    // ------------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    // ------------------------------------------------------------------
    // TabBar
    // ------------------------------------------------------------------
    tabBarTheme: TabBarThemeData(
      labelColor: light.primary,
      unselectedLabelColor: light.onSurfaceVariant,
      indicatorColor: light.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    // ------------------------------------------------------------------
    // SnackBar
    // ------------------------------------------------------------------
    snackBarTheme: SnackBarThemeData(
      backgroundColor: light.inverseSurface,
      contentTextStyle: TextStyle(color: light.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // ------------------------------------------------------------------
    // Dialog
    // ------------------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: light.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
