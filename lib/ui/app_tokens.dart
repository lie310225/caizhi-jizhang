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
  static const double xl = 20;
  static const double hero = 24;
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
// 分类专属色（让流水列表有色彩节奏，避免支出全是红块）
// ==================================================================
abstract final class AppCategoryColors {
  static const Map<String, Color> _map = {
    // 支出
    '餐饮': Color(0xFFEF6C00), // 橙
    '交通': Color(0xFF1565C0), // 蓝
    '购物': Color(0xFFAD1457), // 玫红
    '居住': Color(0xFF6D4C41), // 棕
    '娱乐': Color(0xFF7B1FA2), // 紫
    '医疗': Color(0xFF00897B), // 青
    '理财': Color(0xFF2E7D32), // 绿
    '还贷还借款': Color(0xFFC62828), // 红
    '其他': Color(0xFF546E7A), // 蓝灰
    // 收入
    '工资': Color(0xFF1B5E20), // 深绿
    '奖金': Color(0xFFF9A825), // 金
    '理财收益': Color(0xFF00695C), // 青绿
    '借入款': Color(0xFF283593), // 藏蓝
  };

  static const Color _fallback = Color(0xFF546E7A);

  /// 分类主色
  static Color of(String category) => _map[category] ?? _fallback;

  /// 分类图标底色（约 12% 透明度）
  static Color tintOf(String category) => of(category).withValues(alpha: 0.12);
}

// ==================================================================
// 渐变 token
// ==================================================================
/// 主视觉渐变：手写的三段森林绿，从近黑的墨绿过渡到品牌绿
/// 刻意避开蓝紫色渐变，保持「积累 / 复利」的意象
abstract final class AppGradients {
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A2E15), // 近黑墨绿
      Color(0xFF17451F), // 深林绿
      Color(0xFF2E7D32), // 品牌绿
    ],
    stops: [0.0, 0.52, 1.0],
  );

  /// 收入卡片：亮一档的绿色
  static const LinearGradient income = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
  );
}

// ==================================================================
// 阴影 token
// ==================================================================
abstract final class AppShadows {
  /// 主卡大阴影：大扩散 + 低透明度，产生「浮起来」而非「描边」的感觉
  static List<BoxShadow> hero(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// 列表卡片微阴影
  static List<BoxShadow> soft(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
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

/// 主视觉大数字：字重拉到 800、字距收紧，和附近的小字形成 3 倍以上落差
TextStyle heroMoneyStyle({Color? color}) {
  return TextStyle(
    color: color ?? Colors.white,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
