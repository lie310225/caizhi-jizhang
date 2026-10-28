import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:finance/config/categories.dart';
import 'package:finance/db/database_helper.dart';
import 'package:finance/models/budget.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/services/budgeting.dart';

TransactionRecord _tx(
  String category,
  double amount, {
  String type = 'expense',
}) => TransactionRecord(
  type: type == 'income' ? TxType.income : TxType.expense,
  category: category,
  amount: amount,
  flow: FlowType.operating,
  date: '2026-10-20',
  note: '',
  createdAt: '2026-10-20T10:00:00',
);

void main() {
  group('预算计算', () {
    final records = [
      _tx('餐饮', 300),
      _tx('餐饮', 200),
      _tx('购物', 500),
      _tx('工资', 9000, type: 'income'),
    ];

    test('未设总预算时返回 null', () {
      expect(
        totalBudgetStatus(
          budgets: const [],
          records: records,
          month: '2026-10',
        ),
        isNull,
      );
    });

    test('总预算按当月支出合计计算', () {
      final status = totalBudgetStatus(
        budgets: const [
          Budget(
            month: '2026-10',
            category: Budget.totalCategory,
            amount: 2000,
          ),
        ],
        records: records,
        month: '2026-10',
      );
      expect(status, isNotNull);
      expect(status!.used, 1000);
      expect(status.remaining, 1000);
      expect(status.ratio, closeTo(0.5, 1e-9));
      expect(status.exceeded, isFalse);
    });

    test('超支时 fillRatio 截断在 1', () {
      final status = totalBudgetStatus(
        budgets: const [
          Budget(month: '2026-10', category: Budget.totalCategory, amount: 800),
        ],
        records: records,
        month: '2026-10',
      )!;
      expect(status.exceeded, isTrue);
      expect(status.ratio, closeTo(1.25, 1e-9));
      expect(status.fillRatio, 1.0);
    });

    test('分类预算按使用比例倒序，未设预算的分类不出现', () {
      final list = categoryBudgetStatuses(
        budgets: const [
          Budget(month: '2026-10', category: '餐饮', amount: 1000),
          Budget(month: '2026-10', category: '购物', amount: 400),
        ],
        records: records,
        month: '2026-10',
      );
      expect(list.length, 2);
      expect(list.first.category, '购物');
      expect(list.first.status.exceeded, isTrue);
      expect(list.last.category, '餐饮');
      expect(list.last.status.used, 500);
    });
  });

  group('预算存储', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late DatabaseHelper helper;

    setUp(() async {
      final db = await openCaizhiDatabase(
        databaseFactory,
        inMemoryDatabasePath,
      );
      helper = DatabaseHelper.forDb(db);
    });

    test('同月同类重复写入会覆盖而不是新增', () async {
      await helper.upsertBudget(
        const Budget(month: '2026-10', category: '餐饮', amount: 500),
      );
      await helper.upsertBudget(
        const Budget(month: '2026-10', category: '餐饮', amount: 800),
      );
      final all = await helper.allBudgets();
      expect(all.length, 1);
      expect(all.first.amount, 800);
    });

    test('按月份+分类删除预算', () async {
      await helper.upsertBudget(
        const Budget(month: '2026-10', category: '餐饮', amount: 500),
      );
      await helper.upsertBudget(
        const Budget(month: '2026-11', category: '餐饮', amount: 600),
      );
      expect(await helper.deleteBudget('2026-10', '餐饮'), 1);
      final all = await helper.allBudgets();
      expect(all.length, 1);
      expect(all.first.month, '2026-11');
    });
  });
}
