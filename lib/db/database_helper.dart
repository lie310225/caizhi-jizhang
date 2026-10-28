import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';
import '../models/budget.dart';
import '../models/recurring_bill.dart';

/// 当前数据库版本：v2 budgets、v3 recurrings
const int kDatabaseVersion = 3;

const String _createBudgetsSql = '''
  CREATE TABLE budgets(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    month TEXT NOT NULL,
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    UNIQUE(month, category)
  )
''';

const String _createRecurringsSql = '''
  CREATE TABLE recurrings(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    day_of_month INTEGER NOT NULL,
    active INTEGER NOT NULL DEFAULT 1,
    last_applied_month TEXT
  )
''';

/// 打开（必要时创建）财智数据库。生产与测试共用同一套建表逻辑。
Future<Database> openCaizhiDatabase(DatabaseFactory factory, String path) =>
    factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: kDatabaseVersion,
        // :memory: 路径固定，singleInstance 默认 true 会跨 open 复用同一内存库，
        // 导致测试间数据串扰，这里显式关闭。
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              type TEXT NOT NULL,
              category TEXT NOT NULL,
              amount REAL NOT NULL,
              flow TEXT NOT NULL,
              date TEXT NOT NULL,
              note TEXT,
              created_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE balance_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              kind TEXT NOT NULL,
              name TEXT NOT NULL,
              amount REAL NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute(_createBudgetsSql);
          await db.execute(_createRecurringsSql);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await db.execute(_createBudgetsSql);
          if (oldVersion < 3) await db.execute(_createRecurringsSql);
        },
      ),
    );

/// 数据访问层。单例供生产使用；测试用 forDb 注入内存库。
class DatabaseHelper {
  Database? _injected;
  Database? _db;

  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  DatabaseHelper.forDb(Database db) : _injected = db;

  Future<Database> get _database async {
    if (_injected != null) return _injected!;
    return _db ??= await openCaizhiDatabase(
      databaseFactory,
      p.join(await databaseFactory.getDatabasesPath(), 'caizhi.db'),
    );
  }

  Future<int> insertTransaction(TransactionRecord r) async {
    final db = await _database;
    return db.insert('transactions', r.toMap());
  }

  Future<List<TransactionRecord>> allTransactions() async {
    final db = await _database;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(TransactionRecord.fromMap).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBalanceItem(BalanceItem item) async {
    final db = await _database;
    return db.insert('balance_items', item.toMap());
  }

  Future<List<BalanceItem>> allBalanceItems() async {
    final db = await _database;
    final rows = await db.query('balance_items', orderBy: 'kind ASC, id ASC');
    return rows.map(BalanceItem.fromMap).toList();
  }

  Future<int> deleteBalanceItem(int id) async {
    final db = await _database;
    return db.delete('balance_items', where: 'id = ?', whereArgs: [id]);
  }

  /// 写入预算（同月同分类覆盖），返回受影响行 id
  Future<int> upsertBudget(Budget budget) async {
    final db = await _database;
    return db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> allBudgets() async {
    final db = await _database;
    final rows = await db.query('budgets', orderBy: 'month DESC, category ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<int> deleteBudget(String month, String category) async {
    final db = await _database;
    return db.delete(
      'budgets',
      where: 'month = ? AND category = ?',
      whereArgs: [month, category],
    );
  }

  Future<int> insertRecurring(RecurringBill bill) async {
    final db = await _database;
    return db.insert('recurrings', bill.toMap());
  }

  Future<List<RecurringBill>> allRecurrings() async {
    final db = await _database;
    final rows = await db.query('recurrings', orderBy: 'day_of_month ASC');
    return rows.map(RecurringBill.fromMap).toList();
  }

  Future<int> updateRecurring(RecurringBill bill) async {
    final db = await _database;
    return db.update(
      'recurrings',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<int> deleteRecurring(int id) async {
    final db = await _database;
    return db.delete('recurrings', where: 'id = ?', whereArgs: [id]);
  }
}
