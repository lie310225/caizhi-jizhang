import 'package:flutter_test/flutter_test.dart';
import 'package:finance/config/categories.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/services/tx_filter.dart';

TransactionRecord _tx(
  String date,
  String category,
  double amount, {
  String type = 'expense',
  String note = '',
  int? id,
}) => TransactionRecord(
  id: id,
  type: type == 'income' ? TxType.income : TxType.expense,
  category: category,
  amount: amount,
  flow: FlowType.operating,
  date: date,
  note: note,
  createdAt: '${date}T10:00:00',
);

void main() {
  final records = [
    _tx('2026-10-20', '餐饮', 30, note: '午饭', id: 1),
    _tx('2026-10-18', '购物', 500, note: '外套', id: 2),
    _tx('2026-10-02', '工资', 9000, type: 'income', id: 3),
    _tx('2026-08-11', '餐饮', 66, note: '火锅', id: 4),
    _tx('2025-12-31', '餐饮', 12, note: '夜宵', id: 5),
  ];

  test('默认只看本月并按日期倒序', () {
    final result = filterTransactions(
      records,
      const TxFilter(),
      anchorMonth: '2026-10',
    );
    expect(result.map((r) => r.id), [1, 2, 3]);
  });

  test('近 3 月包含当月与前两个月', () {
    final result = filterTransactions(
      records,
      const TxFilter(range: TxTimeRange.last3Months),
      anchorMonth: '2026-10',
    );
    expect(result.map((r) => r.id), [1, 2, 3, 4]);
  });

  test('按类型过滤收入', () {
    final result = filterTransactions(
      records,
      const TxFilter(type: TxType.income, range: TxTimeRange.all),
      anchorMonth: '2026-10',
    );
    expect(result.single.id, 3);
  });

  test('关键词同时匹配分类与备注', () {
    final byNote = filterTransactions(
      records,
      const TxFilter(query: '火锅', range: TxTimeRange.all),
      anchorMonth: '2026-10',
    );
    expect(byNote.single.id, 4);

    final byCategory = filterTransactions(
      records,
      const TxFilter(query: '餐饮', range: TxTimeRange.all),
      anchorMonth: '2026-10',
    );
    expect(byCategory.length, 3);
  });

  test('分类多选与金额排序', () {
    final result = filterTransactions(
      records,
      const TxFilter(
        categories: {'餐饮', '购物'},
        range: TxTimeRange.all,
        sort: TxSort.amountDesc,
      ),
      anchorMonth: '2026-10',
    );
    expect(result.map((r) => r.amount), [500, 66, 30, 12]);
  });

  test('筛选结果收支合计', () {
    final result = filterTransactions(
      records,
      const TxFilter(range: TxTimeRange.thisMonth),
      anchorMonth: '2026-10',
    );
    final totals = filteredTotals(result);
    expect(totals.income, 9000);
    expect(totals.expense, 530);
    expect(totals.balance, 8470);
  });
}
