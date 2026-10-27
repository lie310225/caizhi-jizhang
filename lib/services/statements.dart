import '../config/categories.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';

/// 期间汇总（period 为 'yyyy-MM' 或 'yyyy' 前缀）
class PeriodSummary {
  final String period;
  final double income;
  final double expense;
  const PeriodSummary(this.period, this.income, this.expense);

  double get balance => income - expense;
  double get savingsRate => income > 0 ? balance / income : 0;
}

/// 现金流三分法净额（收入为正、支出为负）
class CashFlowBreakdown {
  final double operating;
  final double investing;
  final double financing;
  const CashFlowBreakdown(this.operating, this.investing, this.financing);

  double get net => operating + investing + financing;
}

/// 净资产汇总
class NetWorthTotals {
  final double assets;
  final double liabilities;
  const NetWorthTotals(this.assets, this.liabilities);

  double get netWorth => assets - liabilities;
}

/// 'yyyy-MM' 平移 delta 个月，自动处理跨年
String shiftMonth(String month, int delta) {
  final y = int.parse(month.substring(0, 4));
  final m = int.parse(month.substring(5, 7));
  final total = y * 12 + (m - 1) + delta;
  final ny = (total / 12).floor();
  final nm = total % 12 + 1;
  return '${ny.toString().padLeft(4, '0')}-${nm.toString().padLeft(2, '0')}';
}

List<TransactionRecord> _inPeriod(
  List<TransactionRecord> records,
  String prefix,
) => records.where((r) => r.date.startsWith(prefix)).toList();

PeriodSummary summarizePeriod(List<TransactionRecord> records, String prefix) {
  var income = 0.0;
  var expense = 0.0;
  for (final r in _inPeriod(records, prefix)) {
    if (r.type == TxType.income) {
      income += r.amount;
    } else {
      expense += r.amount;
    }
  }
  return PeriodSummary(prefix, income, expense);
}

CashFlowBreakdown cashFlowBreakdown(
  List<TransactionRecord> records,
  String month,
) {
  var op = 0.0;
  var inv = 0.0;
  var fin = 0.0;
  for (final r in _inPeriod(records, month)) {
    final signed = r.type == TxType.income ? r.amount : -r.amount;
    switch (r.flow) {
      case FlowType.operating:
        op += signed;
      case FlowType.investing:
        inv += signed;
      case FlowType.financing:
        fin += signed;
    }
  }
  return CashFlowBreakdown(op, inv, fin);
}

/// 当月各支出分类金额（用于环形图）
Map<String, double> expenseByCategory(
  List<TransactionRecord> records,
  String month,
) {
  final map = <String, double>{};
  for (final r in _inPeriod(records, month)) {
    if (r.type == TxType.expense) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
  }
  return map;
}

/// 以 endMonth 为末月的近 months 个月趋势
List<PeriodSummary> recentMonthTrend(
  List<TransactionRecord> records,
  String endMonth, {
  int months = 6,
}) => [
  for (var i = months - 1; i >= 0; i--)
    summarizePeriod(records, shiftMonth(endMonth, -i)),
];

NetWorthTotals netWorthTotals(List<BalanceItem> items) {
  var a = 0.0;
  var l = 0.0;
  for (final i in items) {
    if (i.isAsset) {
      a += i.amount;
    } else {
      l += i.amount;
    }
  }
  return NetWorthTotals(a, l);
}
