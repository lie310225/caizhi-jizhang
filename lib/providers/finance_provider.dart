import 'package:flutter/foundation.dart';
import '../config/categories.dart';
import '../db/database_helper.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';
import '../services/statements.dart';

/// 全局财务状态：加载、增删、按月筛选、派生报表数据
class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TransactionRecord> _records = [];
  List<BalanceItem> _balanceItems = [];
  String _selectedMonth = _currentMonth();
  bool _loading = false;

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  List<TransactionRecord> get records => List.unmodifiable(_records);
  List<BalanceItem> get balanceItems => List.unmodifiable(_balanceItems);
  String get selectedMonth => _selectedMonth;
  bool get loading => _loading;

  /// 当月记录（allTransactions 已按日期倒序）
  List<TransactionRecord> get monthRecords =>
      _records.where((r) => r.date.startsWith(_selectedMonth)).toList();

  PeriodSummary get monthSummary => summarizePeriod(_records, _selectedMonth);
  PeriodSummary get yearSummary =>
      summarizePeriod(_records, _selectedMonth.substring(0, 4));
  CashFlowBreakdown get cashFlow => cashFlowBreakdown(_records, _selectedMonth);
  Map<String, double> get expenseCategories =>
      expenseByCategory(_records, _selectedMonth);
  List<PeriodSummary> get trend => recentMonthTrend(_records, _selectedMonth);
  NetWorthTotals get totals => netWorthTotals(_balanceItems);

  void setMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void shiftMonthBy(int delta) => setMonth(shiftMonth(_selectedMonth, delta));

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _records = await _db.allTransactions();
    _balanceItems = await _db.allBalanceItems();
    _loading = false;
    notifyListeners();
  }

  Future<void> addTransaction({
    required TxType type,
    required String category,
    required double amount,
    required String date,
    String note = '',
  }) async {
    final record = TransactionRecord(
      type: type,
      category: category,
      amount: amount,
      flow: flowFor(category, type),
      date: date,
      note: note,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertTransaction(record);
    _records = await _db.allTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    _records = await _db.allTransactions();
    notifyListeners();
  }

  Future<void> addBalanceItem({
    required String kind,
    required String name,
    required double amount,
  }) async {
    await _db.insertBalanceItem(
      BalanceItem(
        kind: kind,
        name: name,
        amount: amount,
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
    _balanceItems = await _db.allBalanceItems();
    notifyListeners();
  }

  Future<void> deleteBalanceItem(int id) async {
    await _db.deleteBalanceItem(id);
    _balanceItems = await _db.allBalanceItems();
    notifyListeners();
  }
}
