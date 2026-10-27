import 'package:flutter/material.dart';

// 现金流三分法类型
enum FlowType { operating, investing, financing }

// 交易类型
enum TxType { expense, income }

/// 分类配置：名称 + 交易类型 + 所属现金流
class CategoryConfig {
  final String name;
  final TxType type;
  final FlowType flow;
  const CategoryConfig(this.name, this.type, this.flow);
}

const List<CategoryConfig> kExpenseCategories = [
  CategoryConfig('餐饮', TxType.expense, FlowType.operating),
  CategoryConfig('交通', TxType.expense, FlowType.operating),
  CategoryConfig('购物', TxType.expense, FlowType.operating),
  CategoryConfig('居住', TxType.expense, FlowType.operating),
  CategoryConfig('娱乐', TxType.expense, FlowType.operating),
  CategoryConfig('医疗', TxType.expense, FlowType.operating),
  CategoryConfig('理财', TxType.expense, FlowType.investing),
  CategoryConfig('还贷还借款', TxType.expense, FlowType.financing),
  CategoryConfig('其他', TxType.expense, FlowType.operating),
];

const List<CategoryConfig> kIncomeCategories = [
  CategoryConfig('工资', TxType.income, FlowType.operating),
  CategoryConfig('奖金', TxType.income, FlowType.operating),
  CategoryConfig('理财收益', TxType.income, FlowType.investing),
  CategoryConfig('借入款', TxType.income, FlowType.financing),
  CategoryConfig('其他', TxType.income, FlowType.operating),
];

/// 按分类名+类型查现金流归属；未收录的分类回退为经营性
FlowType flowFor(String category, TxType type) {
  final list = type == TxType.expense ? kExpenseCategories : kIncomeCategories;
  for (final c in list) {
    if (c.name == category) return c.flow;
  }
  return FlowType.operating;
}

/// 分类 → 图标（UI 展示用，未知分类回退 Icons.receipt_long_outlined）
const Map<String, IconData> kCategoryIcons = {
  '餐饮': Icons.restaurant_outlined,
  '交通': Icons.directions_bus_outlined,
  '购物': Icons.shopping_bag_outlined,
  '居住': Icons.home_outlined,
  '娱乐': Icons.sports_esports_outlined,
  '医疗': Icons.local_hospital_outlined,
  '理财': Icons.savings_outlined,
  '还贷还借款': Icons.credit_score_outlined,
  '工资': Icons.work_outline,
  '奖金': Icons.emoji_events_outlined,
  '理财收益': Icons.trending_up_outlined,
  '借入款': Icons.handshake_outlined,
  '其他': Icons.more_horiz,
};
