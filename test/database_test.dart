import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:finance/db/database_helper.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/models/balance_item.dart';
import 'package:finance/config/categories.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;

  setUp(() async {
    final db = await openCaizhiDatabase(databaseFactory, inMemoryDatabasePath);
    helper = DatabaseHelper.forDb(db);
  });

  test('插入并读回交易记录', () async {
    final r = const TransactionRecord(
      type: TxType.expense,
      category: '餐饮',
      amount: 25.5,
      flow: FlowType.operating,
      date: '2026-10-27',
      note: '午饭',
      createdAt: '2026-10-27T12:00:00',
    );
    final id = await helper.insertTransaction(r);
    expect(id, greaterThan(0));
    final all = await helper.allTransactions();
    expect(all.length, 1);
    expect(all.first.category, '餐饮');
    expect(all.first.amount, 25.5);
  });

  test('删除交易记录', () async {
    final id = await helper.insertTransaction(
      const TransactionRecord(
        type: TxType.income,
        category: '工资',
        amount: 8000,
        flow: FlowType.operating,
        date: '2026-10-01',
        note: '',
        createdAt: '2026-10-01T09:00:00',
      ),
    );
    expect(await helper.deleteTransaction(id), 1);
    expect(await helper.allTransactions(), isEmpty);
  });

  test('资产负债条目增删读', () async {
    final id = await helper.insertBalanceItem(
      const BalanceItem(
        kind: 'asset',
        name: '活期存款',
        amount: 12000,
        updatedAt: '',
      ),
    );
    await helper.insertBalanceItem(
      const BalanceItem(
        kind: 'liability',
        name: '消费贷',
        amount: 3000,
        updatedAt: '',
      ),
    );
    final items = await helper.allBalanceItems();
    expect(items.length, 2);
    expect(await helper.deleteBalanceItem(id), 1);
    expect((await helper.allBalanceItems()).length, 1);
  });
}
