import '../config/categories.dart';
import '../models/transaction_record.dart';
import 'statements.dart';

// ==================================================================
// 类型定义
// ==================================================================
/// 搜索的时间范围
enum TxTimeRange { thisMonth, last3Months, thisYear, all }

/// 搜索结果的排序方式
enum TxSort { dateDesc, amountDesc }

extension TxTimeRangeLabel on TxTimeRange {
  String get label => switch (this) {
    TxTimeRange.thisMonth => '本月',
    TxTimeRange.last3Months => '近 3 月',
    TxTimeRange.thisYear => '今年',
    TxTimeRange.all => '全部',
  };
}

/// 流水筛选条件
class TxFilter {
  final String query;
  final TxType? type;
  final Set<String> categories;
  final TxTimeRange range;
  final TxSort sort;

  const TxFilter({
    this.query = '',
    this.type,
    this.categories = const {},
    this.range = TxTimeRange.thisMonth,
    this.sort = TxSort.dateDesc,
  });

  bool get hasCondition =>
      query.trim().isNotEmpty || type != null || categories.isNotEmpty;

  TxFilter copyWith({
    String? query,
    TxType? type,
    bool clearType = false,
    Set<String>? categories,
    TxTimeRange? range,
    TxSort? sort,
  }) => TxFilter(
    query: query ?? this.query,
    type: clearType ? null : (type ?? this.type),
    categories: categories ?? this.categories,
    range: range ?? this.range,
    sort: sort ?? this.sort,
  );
}

// ==================================================================
// 计算
// ==================================================================
/// 时间范围换算成需要匹配的月份前缀集合；null 表示不限
Set<String>? _monthPrefixes(TxTimeRange range, String anchorMonth) {
  switch (range) {
    case TxTimeRange.all:
      return null;
    case TxTimeRange.thisMonth:
      return {anchorMonth};
    case TxTimeRange.last3Months:
      return {for (var i = 0; i < 3; i++) shiftMonth(anchorMonth, -i)};
    case TxTimeRange.thisYear:
      return {anchorMonth.substring(0, 4)};
  }
}

/// 按条件过滤 + 排序（关键词匹配分类名与备注）
List<TransactionRecord> filterTransactions(
  List<TransactionRecord> records,
  TxFilter filter, {
  required String anchorMonth,
}) {
  final prefixes = _monthPrefixes(filter.range, anchorMonth);
  final keyword = filter.query.trim().toLowerCase();

  final result = records.where((r) {
    if (filter.type != null && r.type != filter.type) return false;
    if (filter.categories.isNotEmpty &&
        !filter.categories.contains(r.category)) {
      return false;
    }
    if (prefixes != null &&
        !prefixes.any((prefix) => r.date.startsWith(prefix))) {
      return false;
    }
    if (keyword.isNotEmpty) {
      final hit =
          r.category.toLowerCase().contains(keyword) ||
          r.note.toLowerCase().contains(keyword);
      if (!hit) return false;
    }
    return true;
  }).toList();

  switch (filter.sort) {
    case TxSort.dateDesc:
      result.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
      });
    case TxSort.amountDesc:
      result.sort((a, b) => b.amount.compareTo(a.amount));
  }
  return result;
}

/// 筛选结果的收入 / 支出合计
class FilteredTotals {
  final double income;
  final double expense;

  const FilteredTotals({required this.income, required this.expense});

  double get balance => income - expense;
}

FilteredTotals filteredTotals(List<TransactionRecord> records) {
  var income = 0.0;
  var expense = 0.0;
  for (final r in records) {
    if (r.type == TxType.income) {
      income += r.amount;
    } else {
      expense += r.amount;
    }
  }
  return FilteredTotals(income: income, expense: expense);
}
