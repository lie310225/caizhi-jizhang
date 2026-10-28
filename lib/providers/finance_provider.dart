import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../config/categories.dart';
import '../db/database_helper.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';
import '../models/budget.dart';
import '../models/recurring_bill.dart';
import '../services/budgeting.dart';
import '../services/csv_export.dart';
import '../services/recurring.dart';
import '../services/statements.dart';

/// 全局财务状态：加载、增删、按月筛选、派生报表数据
class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TransactionRecord> _records = [];
  List<BalanceItem> _balanceItems = [];
  List<Budget> _budgets = [];
  List<RecurringBill> _recurringBills = [];
  String _selectedMonth = _currentMonth();
  bool _loading = false;

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  List<TransactionRecord> get records => List.unmodifiable(_records);
  List<BalanceItem> get balanceItems => List.unmodifiable(_balanceItems);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<RecurringBill> get recurringBills => List.unmodifiable(_recurringBills);
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

  /// 当月总预算执行情况（未设总预算为 null）
  BudgetStatus? get monthBudgetStatus => totalBudgetStatus(
    budgets: _budgets,
    records: _records,
    month: _selectedMonth,
  );

  /// 当月各分类预算执行情况
  List<CategoryBudgetStatus> get monthCategoryBudgetStatuses =>
      categoryBudgetStatuses(
        budgets: _budgets,
        records: _records,
        month: _selectedMonth,
      );

  /// 某分类当月预算额度；未设置返回 null
  double? budgetLimitOf(String category) =>
      budgetLimitFor(_budgets, _selectedMonth, category);

  /// 写入当月预算（amount <= 0 视为清除该条预算）
  Future<void> setBudget({
    String category = Budget.totalCategory,
    required double amount,
  }) async {
    if (amount <= 0) {
      await _db.deleteBudget(_selectedMonth, category);
    } else {
      await _db.upsertBudget(
        Budget(month: _selectedMonth, category: category, amount: amount),
      );
    }
    _budgets = await _db.allBudgets();
    notifyListeners();
  }

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
    _budgets = await _db.allBudgets();
    _recurringBills = await _db.allRecurrings();
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

  // ---------------- 周期账单 ----------------

  /// 当月到期且尚未记账的周期账单
  List<RecurringBill> get monthDueRecurrings => dueRecurrings(
    _recurringBills,
    month: _selectedMonth,
    today: todayString(),
  );

  Future<void> addRecurring({
    required String title,
    required String category,
    required TxType type,
    required double amount,
    required int dayOfMonth,
  }) async {
    await _db.insertRecurring(
      RecurringBill(
        title: title,
        category: category,
        type: type,
        amount: amount,
        dayOfMonth: dayOfMonth,
      ),
    );
    _recurringBills = await _db.allRecurrings();
    notifyListeners();
  }

  Future<void> toggleRecurring(RecurringBill bill, bool active) async {
    await _db.updateRecurring(bill.copyWith(active: active));
    _recurringBills = await _db.allRecurrings();
    notifyListeners();
  }

  Future<void> deleteRecurring(int id) async {
    await _db.deleteRecurring(id);
    _recurringBills = await _db.allRecurrings();
    notifyListeners();
  }

  /// 把某笔周期账单记入当月流水，并标记本月已记
  Future<void> applyRecurring(RecurringBill bill) async {
    await _db.insertTransaction(
      TransactionRecord(
        type: bill.type,
        category: bill.category,
        amount: bill.amount,
        flow: flowFor(bill.category, bill.type),
        date: recurringDate(bill, _selectedMonth),
        note: bill.title,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _db.updateRecurring(bill.copyWith(lastAppliedMonth: _selectedMonth));
    _records = await _db.allTransactions();
    _recurringBills = await _db.allRecurrings();
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

  /// 按日期字符串前缀过滤 records
  List<TransactionRecord> _filterByDate(
    List<TransactionRecord> records, {
    String? monthPrefix,
    String? yearPrefix,
  }) {
    return records.where((r) {
      if (yearPrefix != null && !r.date.startsWith(yearPrefix)) return false;
      if (monthPrefix != null && !r.date.startsWith(monthPrefix)) return false;
      return true;
    }).toList();
  }

  /// 导出 CSV zip 到临时文件，返回文件路径（分享用）
  Future<String> exportCsvZip({String? monthPrefix, String? yearPrefix}) async {
    final filtered = _filterByDate(
      _records,
      monthPrefix: monthPrefix,
      yearPrefix: yearPrefix,
    );
    final zipBytes = await csvZipData(filtered, _balanceItems);
    final dir = await Directory.systemTemp.createTemp('caizhi-');
    final file = File(p.join(dir.path, defaultZipFileName()));
    await file.writeAsBytes(zipBytes);
    return file.path;
  }
}
