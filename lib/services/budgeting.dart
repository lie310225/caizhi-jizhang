import '../models/budget.dart';
import '../models/transaction_record.dart';
import 'statements.dart';

// ==================================================================
// 类型定义
// ==================================================================
/// 单个预算的执行情况（limit 为 0 表示未设预算）
class BudgetStatus {
  final double limit;
  final double used;

  const BudgetStatus({required this.limit, required this.used});

  bool get isSet => limit > 0;

  double get remaining => limit - used;

  bool get exceeded => isSet && used > limit;

  /// 实际使用比例，可能大于 1
  double get ratio => isSet ? used / limit : 0;

  /// 进度条填充比例，超支时截断在 1
  double get fillRatio => ratio.clamp(0.0, 1.0);
}

/// 分类预算 + 分类名
class CategoryBudgetStatus {
  final String category;
  final BudgetStatus status;

  const CategoryBudgetStatus({required this.category, required this.status});
}

// ==================================================================
// 计算
// ==================================================================
/// 取某月某分类的预算额度；未设置返回 null
double? budgetLimitFor(List<Budget> budgets, String month, String category) {
  for (final b in budgets) {
    if (b.month == month && b.category == category) return b.amount;
  }
  return null;
}

/// 总预算执行情况：未设总预算时返回 null
BudgetStatus? totalBudgetStatus({
  required List<Budget> budgets,
  required List<TransactionRecord> records,
  required String month,
}) {
  final limit = budgetLimitFor(budgets, month, Budget.totalCategory);
  if (limit == null || limit <= 0) return null;
  return BudgetStatus(
    limit: limit,
    used: summarizePeriod(records, month).expense,
  );
}

/// 已设置预算的支出分类执行情况，按使用比例从高到低排列（超支优先）
List<CategoryBudgetStatus> categoryBudgetStatuses({
  required List<Budget> budgets,
  required List<TransactionRecord> records,
  required String month,
}) {
  final spent = expenseByCategory(records, month);
  final result = <CategoryBudgetStatus>[];
  for (final b in budgets) {
    if (b.month != month || b.isTotal || b.amount <= 0) continue;
    result.add(
      CategoryBudgetStatus(
        category: b.category,
        status: BudgetStatus(limit: b.amount, used: spent[b.category] ?? 0),
      ),
    );
  }
  result.sort((a, b) => b.status.ratio.compareTo(a.status.ratio));
  return result;
}
