import 'package:flutter_test/flutter_test.dart';
import 'package:finance/config/categories.dart';

void main() {
  test('分类映射到正确的现金流三分法', () {
    expect(flowFor('餐饮', TxType.expense), FlowType.operating);
    expect(flowFor('理财', TxType.expense), FlowType.investing);
    expect(flowFor('还贷还借款', TxType.expense), FlowType.financing);
    expect(flowFor('工资', TxType.income), FlowType.operating);
    expect(flowFor('理财收益', TxType.income), FlowType.investing);
    expect(flowFor('借入款', TxType.income), FlowType.financing);
  });

  test('未知分类回退为经营性', () {
    expect(flowFor('不存在', TxType.expense), FlowType.operating);
  });

  test('支出与收入分类表非空且无重名', () {
    expect(kExpenseCategories, isNotEmpty);
    expect(kIncomeCategories, isNotEmpty);
    final expenseNames = kExpenseCategories.map((c) => c.name).toList();
    final incomeNames = kIncomeCategories.map((c) => c.name).toList();
    expect(expenseNames.length, expenseNames.toSet().length);
    expect(incomeNames.length, incomeNames.toSet().length);
  });
}
