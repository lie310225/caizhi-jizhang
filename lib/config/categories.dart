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
