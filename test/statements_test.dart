import 'package:flutter_test/flutter_test.dart';
import 'package:finance/services/statements.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/models/balance_item.dart';
import 'package:finance/config/categories.dart';

TransactionRecord tx(
  TxType type,
  String category,
  double amount,
  String date,
) => TransactionRecord(
  type: type,
  category: category,
  amount: amount,
  flow: flowFor(category, type),
  date: date,
  note: '',
  createdAt: '',
);

void main() {
  final records = [
    tx(TxType.income, '工资', 10000, '2026-10-10'),
    tx(TxType.expense, '餐饮', 1000, '2026-10-11'),
    tx(TxType.expense, '理财', 2000, '2026-10-12'),
    tx(TxType.expense, '还贷还借款', 3000, '2026-10-13'),
    tx(TxType.income, '工资', 8000, '2026-09-05'),
    tx(TxType.expense, '交通', 200, '2026-09-06'),
  ];

  test('月度汇总与储蓄率', () {
    final s = summarizePeriod(records, '2026-10');
    expect(s.income, 10000);
    expect(s.expense, 6000);
    expect(s.balance, 4000);
    expect(s.savingsRate, closeTo(0.4, 1e-9));
  });

  test('收入为零时储蓄率为 0', () {
    final s = summarizePeriod([
      tx(TxType.expense, '餐饮', 100, '2026-10-01'),
    ], '2026-10');
    expect(s.savingsRate, 0);
  });

  test('年度汇总跨月累计', () {
    final s = summarizePeriod(records, '2026');
    expect(s.income, 18000);
    expect(s.expense, 6200);
  });

  test('现金流三分法', () {
    final c = cashFlowBreakdown(records, '2026-10');
    expect(c.operating, 9000);
    expect(c.investing, -2000);
    expect(c.financing, -3000);
    expect(c.net, 4000);
  });

  test('支出分类占比', () {
    final m = expenseByCategory(records, '2026-10');
    expect(m['餐饮'], 1000);
    expect(m['理财'], 2000);
    expect(m.containsKey('交通'), isFalse);
  });

  test('近 6 个月趋势', () {
    final t = recentMonthTrend(records, '2026-10');
    expect(t.length, 6);
    expect(t.first.period, '2026-05');
    expect(t.last.period, '2026-10');
  });

  test('月份平移跨年', () {
    expect(shiftMonth('2026-01', -1), '2025-12');
    expect(shiftMonth('2026-10', 3), '2027-01');
  });

  test('净资产汇总', () {
    final n = netWorthTotals(const [
      BalanceItem(kind: 'asset', name: '存款', amount: 12000, updatedAt: ''),
      BalanceItem(kind: 'liability', name: '消费贷', amount: 3000, updatedAt: ''),
    ]);
    expect(n.assets, 12000);
    expect(n.liabilities, 3000);
    expect(n.netWorth, 9000);
  });
}
