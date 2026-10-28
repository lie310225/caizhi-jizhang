import 'package:flutter/material.dart';

// ==================================================================
// 间距 token
// ==================================================================
/// 间距层级：4 / 8 / 12 / 16 / 24 / 32
abstract final class AppSpacing {
  static const double xxxs = 4;
  static const double xxs = 8;
  static const double xs = 12;
  static const double s = 16;
  static const double m = 24;
  static const double l = 32;
}

// ==================================================================
// 圆角 token
// ==================================================================
abstract final class AppRadius {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
}

// ==================================================================
// 业务语义颜色（不依赖主题派生，确保收入/支出始终可读）
// ==================================================================
abstract final class AppSemanticColors {
  static const Color income = Color(0xFF1B5E20); // 深墨绿
  static const Color expense = Color(0xFFC62828); // 暗红
  static const Color balance = Color(0xFF283593); // 深藏蓝

  /// 支出分类环形图调色板（9 色，业务语义色，不跟随主题）
  static const List<Color> expensePalette = [
    Color(0xFF1B5E20),
    Color(0xFF43A047),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFF8E24AA),
    Color(0xFF5C6BC0),
    Color(0xFFC62828),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
  ];
}

// ==================================================================
// 数字文本样式（Tabular 等宽 + 右对齐友好）
// ==================================================================
TextStyle moneyStyle(
  BuildContext context, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
}) {
  final base =
      Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  return base.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

TextStyle moneyStyleSmall(BuildContext context, {Color? color}) {
  final base =
      Theme.of(context).textTheme.titleSmall ?? const TextStyle(fontSize: 14);
  return base.copyWith(
    color: color,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
