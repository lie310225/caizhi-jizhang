# 财智记账 Android MVP 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按设计文档把"财智记账"MVP（记账 + 利润表 + 现金流量表 + 资产负债表）落地为 Flutter 应用，产出可安装的 release APK。

**Architecture:** 单机应用。SQLite（sqflite）存两张表；纯函数服务层做报表聚合（可单测）；provider 状态管理；底部 4 Tab UI（记账 / 报表 / 资产负债 / 我的）。代码位于工作目录 `caizhi-app/`（独立 git 仓库，不混入 finance-app-proposal）。

**Tech Stack:** Flutter 3.41.4 / Dart 3.11、sqflite、provider、fl_chart、intl；Android SDK 36 + JDK 17。

**约定：** 所有代码文件按"类型定义 → 常量 → 组件主体 → 导出语句"组织；全程 UTF-8；提交前跑 `flutter analyze`；UI 由需求方人工验证。

---

## 文件结构

```
caizhi-app/
├── pubspec.yaml                        # 依赖：sqflite/provider/fl_chart/intl；dev: sqflite_common_ffi
├── android/                            # flutter create 生成（改 settings.gradle 加阿里云镜像）
├── lib/
│   ├── main.dart                       # 入口：Provider + MaterialApp
│   ├── config/
│   │   └── categories.dart             # TxType/FlowType 枚举、分类常量、flowFor 映射
│   ├── models/
│   │   ├── transaction_record.dart     # 交易模型 + toMap/fromMap
│   │   └── balance_item.dart           # 资产/负债条目模型
│   ├── db/
│   │   └── database_helper.dart        # 建表 + CRUD（支持测试注入）
│   ├── services/
│   │   ├── statements.dart             # 纯函数：利润表/现金流/净资产/趋势聚合
│   │   └── format.dart                 # fmtMoney/monthLabel 等格式化
│   ├── providers/
│   │   └── finance_provider.dart       # ChangeNotifier：数据加载与增删、派生报表数据
│   └── ui/
│       ├── theme.dart                  # Material 3 绿色主题
│       ├── root_tabs.dart              # NavigationBar 4 Tab 骨架
│       ├── pages/
│       │   ├── home_page.dart          # 流水首页（月切换/汇总/列表/FAB）
│       │   ├── add_transaction_sheet.dart # 记一笔底部弹窗表单
│       │   ├── reports_page.dart       # 利润表/现金流 Tab + 折线图/环形图
│       │   ├── balance_page.dart       # 资产负债表 + 条目管理
│       │   └── mine_page.dart          # 我的（知识模块 v2 占位）
├── test/
│   ├── categories_test.dart            # 分类→现金流映射测试
│   ├── statements_test.dart            # 报表聚合测试
│   └── database_test.dart              # sqflite_common_ffi CRUD 冒烟测试
```

## 全局环境准备（执行任何任务前）

所有 PowerShell 会话先执行（国内镜像，避免 pub 卡住）：

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
```

---

### Task 1: 项目脚手架与依赖

**Files:**
- Create: `caizhi-app/`（flutter create 生成整棵树）
- Modify: `caizhi-app/pubspec.yaml`（加依赖）
- Modify: `caizhi-app/android/settings.gradle.kts` 或 `settings.gradle`（加阿里云镜像）

- [ ] **Step 1: 创建 Flutter 项目**

```powershell
flutter create --org com.caizhi --project-name finance --platforms android caizhi-app
```

预期：生成 `caizhi-app/`，`android/app/build.gradle(.kts)` 中 applicationId 为 `com.caizhi.finance`。

- [ ] **Step 2: 初始化独立 git 仓库**

```powershell
git -C caizhi-app init -b main
git -C caizhi-app config user.name "lie310225"
git -C caizhi-app config user.email "286658154+lie310225@users.noreply.github.com"
```

- [ ] **Step 3: 修改 pubspec.yaml 依赖**

在 `dependencies:` 下追加（保留 flutter 段）：

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.4.1
  path: ^1.9.0
  provider: ^6.1.2
  fl_chart: ^0.70.2
  intl: ^0.19.0
```

在 `dev_dependencies:` 下追加：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  sqflite_common_ffi: ^2.3.3
```

- [ ] **Step 4: 拉取依赖**

```powershell
cd caizhi-app; flutter pub get; cd ..
```

预期：`Got dependencies!`。若 fl_chart/intl 版本冲突，以 pub 提示的兼容版本为准调整约束后重试。

- [ ] **Step 5: Gradle 仓库加阿里云镜像（先尝试直连，失败再做本步）**

先跑 `cd caizhi-app; flutter analyze; cd ..` 触发 gradle 依赖解析不必要——analyze 不走 gradle，可跳过。**默认直接做镜像**（maven.google.com 已知超时）：

若存在 `android/settings.gradle.kts`，在 `pluginManagement { repositories { ... } }` 的 `google()` 之前插入：

```kotlin
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
```

若是旧版 `android/settings.gradle`（Groovy），在 `google()` 之前插入：

```groovy
        maven { url "https://maven.aliyun.com/repository/google" }
        maven { url "https://maven.aliyun.com/repository/public" }
        maven { url "https://maven.aliyun.com/repository/gradle-plugin" }
```

- [ ] **Step 6: 首次提交**

```powershell
git -C caizhi-app add -A
git -C caizhi-app commit -m "chore: Flutter 项目脚手架与依赖"
```

### Task 2: 类型定义、分类配置与交易模型（TDD）

**Files:**
- Create: `lib/config/categories.dart`
- Create: `lib/models/transaction_record.dart`
- Create: `lib/models/balance_item.dart`
- Test: `test/categories_test.dart`

- [ ] **Step 1: 写失败测试 `test/categories_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finance/config/categories.dart';

void main() {
  test('分类映射到正确的现金流三分法', () {
    expect(flowFor('餐饮', TxType.expense), FlowType.operating);
    expect(flowFor('理财', TxType.expense), FlowType.investing);
    expect(flowFor('还贷还借款', TxType.expense), FlowType.financing);
    expect(flowFor('工资', TxType.income), FlowType.operating);
    expect(flowFor('理财收益', TxType.income), FlowType.investing);
    expect(flowFor('借入款', TxType.income), FlowType.financing);
  });

  test('未知分类回退为经营性', () {
    expect(flowFor('不存在', TxType.expense), FlowType.operating);
  });

  test('支出与收入分类表非空且无重名', () {
    expect(kExpenseCategories, isNotEmpty);
    expect(kIncomeCategories, isNotEmpty);
    final names = [...kExpenseCategories, ...kIncomeCategories].map((c) => c.name).toList();
    expect(names.length, names.toSet().length);
  });
}
```

- [ ] **Step 2: 运行确认失败**

```powershell
cd caizhi-app; flutter test test/categories_test.dart; cd ..
```

预期：FAIL（找不到 `package:finance/config/categories.dart`）。

- [ ] **Step 3: 实现 `lib/config/categories.dart`**

```dart
// 现金流三分法类型
enum FlowType { operating, investing, financing }

// 交易类型
enum TxType { expense, income }

/// 分类配置：名称 + 交易类型 + 所属现金流
class CategoryConfig {
  final String name;
  final TxType type;
  final FlowType flow;
  const CategoryConfig(this.name, this.type, this.flow);
}

const List<CategoryConfig> kExpenseCategories = [
  CategoryConfig('餐饮', TxType.expense, FlowType.operating),
  CategoryConfig('交通', TxType.expense, FlowType.operating),
  CategoryConfig('购物', TxType.expense, FlowType.operating),
  CategoryConfig('居住', TxType.expense, FlowType.operating),
  CategoryConfig('娱乐', TxType.expense, FlowType.operating),
  CategoryConfig('医疗', TxType.expense, FlowType.operating),
  CategoryConfig('理财', TxType.expense, FlowType.investing),
  CategoryConfig('还贷还借款', TxType.expense, FlowType.financing),
  CategoryConfig('其他', TxType.expense, FlowType.operating),
];

const List<CategoryConfig> kIncomeCategories = [
  CategoryConfig('工资', TxType.income, FlowType.operating),
  CategoryConfig('奖金', TxType.income, FlowType.operating),
  CategoryConfig('理财收益', TxType.income, FlowType.investing),
  CategoryConfig('借入款', TxType.income, FlowType.financing),
  CategoryConfig('其他', TxType.income, FlowType.operating),
];

/// 按分类名+类型查现金流归属；未收录的分类回退为经营性
FlowType flowFor(String category, TxType type) {
  final list = type == TxType.expense ? kExpenseCategories : kIncomeCategories;
  for (final c in list) {
    if (c.name == category) return c.flow;
  }
  return FlowType.operating;
}
```

- [ ] **Step 4: 实现 `lib/models/transaction_record.dart`**

```dart
import '../config/categories.dart';

/// 一笔交易记录
class TransactionRecord {
  final int? id;
  final TxType type;
  final String category;
  final double amount;
  final FlowType flow;
  final String date; // yyyy-MM-dd
  final String note;
  final String createdAt; // ISO8601

  const TransactionRecord({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.flow,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'category': category,
        'amount': amount,
        'flow': flow.name,
        'date': date,
        'note': note,
        'created_at': createdAt,
      };

  factory TransactionRecord.fromMap(Map<String, Object?> map) => TransactionRecord(
        id: map['id'] as int?,
        type: TxType.values.byName(map['type'] as String),
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        flow: FlowType.values.byName(map['flow'] as String),
        date: map['date'] as String,
        note: (map['note'] as String?) ?? '',
        createdAt: (map['created_at'] as String?) ?? '',
      );

  /// 复制并允许覆盖字段（用于派生记录）
  TransactionRecord copyWith({int? id, TxType? type, String? category, double? amount,
      FlowType? flow, String? date, String? note}) =>
      TransactionRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        flow: flow ?? this.flow,
        date: date ?? this.date,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}
```

- [ ] **Step 5: 实现 `lib/models/balance_item.dart`**

```dart
/// 资产负债条目：kind = 'asset' | 'liability'
class BalanceItem {
  final int? id;
  final String kind;
  final String name;
  final double amount;
  final String updatedAt;

  const BalanceItem({
    this.id,
    required this.kind,
    required this.name,
    required this.amount,
    required this.updatedAt,
  });

  bool get isAsset => kind == 'asset';

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind,
        'name': name,
        'amount': amount,
        'updated_at': updatedAt,
      };

  factory BalanceItem.fromMap(Map<String, Object?> map) => BalanceItem(
        id: map['id'] as int?,
        kind: map['kind'] as String,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        updatedAt: (map['updated_at'] as String?) ?? '',
      );
}
```

- [ ] **Step 6: 运行测试确认通过**

```powershell
cd caizhi-app; flutter test test/categories_test.dart; cd ..
```

预期：`All tests passed!`

- [ ] **Step 7: 提交**

```powershell
git -C caizhi-app add lib test
git -C caizhi-app commit -m "feat: 类型定义、分类配置与数据模型"
```

### Task 3: 数据库层（TDD，sqflite_common_ffi）

**Files:**
- Create: `lib/db/database_helper.dart`
- Test: `test/database_test.dart`

- [ ] **Step 1: 写失败测试 `test/database_test.dart`**

```dart
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
    final id = await helper.insertTransaction(const TransactionRecord(
      type: TxType.income,
      category: '工资',
      amount: 8000,
      flow: FlowType.operating,
      date: '2026-10-01',
      note: '',
      createdAt: '2026-10-01T09:00:00',
    ));
    expect(await helper.deleteTransaction(id), 1);
    expect(await helper.allTransactions(), isEmpty);
  });

  test('资产负债条目增删读', () async {
    final id = await helper.insertBalanceItem(
        const BalanceItem(kind: 'asset', name: '活期存款', amount: 12000, updatedAt: ''));
    await helper.insertBalanceItem(
        const BalanceItem(kind: 'liability', name: '消费贷', amount: 3000, updatedAt: ''));
    final items = await helper.allBalanceItems();
    expect(items.length, 2);
    expect(await helper.deleteBalanceItem(id), 1);
    expect((await helper.allBalanceItems()).length, 1);
  });
}
```

- [ ] **Step 2: 运行确认失败**

```powershell
cd caizhi-app; flutter test test/database_test.dart; cd ..
```

预期：FAIL（找不到 `package:finance/db/database_helper.dart`）。

- [ ] **Step 3: 实现 `lib/db/database_helper.dart`**

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';

/// 打开（必要时创建）财智数据库。生产与测试共用同一套建表逻辑。
Future<Database> openCaizhiDatabase(DatabaseFactory factory, String path) =>
    factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
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
        databaseFactory, p.join(await databaseFactory.getDatabasesPath(), 'caizhi.db'));
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
}
```

- [ ] **Step 4: 运行测试确认通过**

```powershell
cd caizhi-app; flutter test test/database_test.dart; cd ..
```

预期：`All tests passed!`

- [ ] **Step 5: 提交**

```powershell
git -C caizhi-app add lib test
git -C caizhi-app commit -m "feat: SQLite 数据层与建表逻辑"
```

### Task 4: 报表聚合服务与格式化工具（TDD，纯 Dart）

**Files:**
- Create: `lib/services/statements.dart`
- Create: `lib/services/format.dart`
- Test: `test/statements_test.dart`

- [ ] **Step 1: 写失败测试 `test/statements_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finance/services/statements.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/models/balance_item.dart';
import 'package:finance/config/categories.dart';

TransactionRecord tx(TxType type, String category, double amount, String date) =>
    TransactionRecord(
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
    final s = summarizePeriod([tx(TxType.expense, '餐饮', 100, '2026-10-01')], '2026-10');
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
```

- [ ] **Step 2: 运行确认失败**

```powershell
cd caizhi-app; flutter test test/statements_test.dart; cd ..
```

预期：FAIL（找不到 `package:finance/services/statements.dart`）。

- [ ] **Step 3: 实现 `lib/services/statements.dart`**

```dart
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

List<TransactionRecord> _inPeriod(List<TransactionRecord> records, String prefix) =>
    records.where((r) => r.date.startsWith(prefix)).toList();

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

CashFlowBreakdown cashFlowBreakdown(List<TransactionRecord> records, String month) {
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
Map<String, double> expenseByCategory(List<TransactionRecord> records, String month) {
  final map = <String, double>{};
  for (final r in _inPeriod(records, month)) {
    if (r.type == TxType.expense) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
  }
  return map;
}

/// 以 endMonth 为末月的近 months 个月趋势
List<PeriodSummary> recentMonthTrend(List<TransactionRecord> records, String endMonth,
    {int months = 6}) => [
      for (var i = months - 1; i >= 0; i--)
        summarizePeriod(records, shiftMonth(endMonth, -i))
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
```

- [ ] **Step 4: 实现 `lib/services/format.dart`**

```dart
import 'package:intl/intl.dart';

final NumberFormat _moneyFmt = NumberFormat('#,##0.00');

/// 金额格式化：12,345.67
String fmtMoney(double v) => _moneyFmt.format(v);

/// 'yyyy-MM' → 'yyyy年MM月'
String monthLabel(String month) {
  final parts = month.split('-');
  return '${parts[0]}年${parts[1]}月';
}

/// 'yyyy-MM-dd' → 'MM-dd'
String dayLabel(String date) => date.length >= 10 ? date.substring(5) : date;
```

- [ ] **Step 5: 运行测试确认通过**

```powershell
cd caizhi-app; flutter test test/statements_test.dart; cd ..
```

预期：`All tests passed!`

- [ ] **Step 6: 提交**

```powershell
git -C caizhi-app add lib test
git -C caizhi-app commit -m "feat: 报表聚合服务与格式化工具"
```

### Task 5: 状态管理层（Provider）

**Files:**
- Create: `lib/providers/finance_provider.dart`

- [ ] **Step 1: 实现 `lib/providers/finance_provider.dart`**

```dart
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
  PeriodSummary get yearSummary => summarizePeriod(_records, _selectedMonth.substring(0, 4));
  CashFlowBreakdown get cashFlow => cashFlowBreakdown(_records, _selectedMonth);
  Map<String, double> get expenseCategories => expenseByCategory(_records, _selectedMonth);
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

  Future<void> addBalanceItem(
      {required String kind, required String name, required double amount}) async {
    await _db.insertBalanceItem(BalanceItem(
        kind: kind, name: name, amount: amount, updatedAt: DateTime.now().toIso8601String()));
    _balanceItems = await _db.allBalanceItems();
    notifyListeners();
  }

  Future<void> deleteBalanceItem(int id) async {
    await _db.deleteBalanceItem(id);
    _balanceItems = await _db.allBalanceItems();
    notifyListeners();
  }
}
```

- [ ] **Step 2: 静态检查**

```powershell
cd caizhi-app; flutter analyze; cd ..
```

预期：`No issues found!`

- [ ] **Step 3: 提交**

```powershell
git -C caizhi-app add lib
git -C caizhi-app commit -m "feat: FinanceProvider 状态管理"
```

### Task 6: 主题、入口与底部导航骨架

**Files:**
- Create: `lib/ui/theme.dart`
- Create: `lib/ui/root_tabs.dart`
- Create: `lib/ui/pages/mine_page.dart`
- Modify: `lib/main.dart`（整体替换）
- Modify: `lib/config/categories.dart`（追加图标映射常量）

- [ ] **Step 1: 在 `lib/config/categories.dart` 末尾追加图标映射（import 区加 `import 'package:flutter/material.dart';`）**

```dart
/// 分类 → 图标（UI 展示用，未知分类回退 Icons.receipt_long_outlined）
const Map<String, IconData> kCategoryIcons = {
  '餐饮': Icons.restaurant_outlined,
  '交通': Icons.directions_bus_outlined,
  '购物': Icons.shopping_bag_outlined,
  '居住': Icons.home_outlined,
  '娱乐': Icons.sports_esports_outlined,
  '医疗': Icons.local_hospital_outlined,
  '理财': Icons.savings_outlined,
  '还贷还借款': Icons.credit_score_outlined,
  '工资': Icons.work_outline,
  '奖金': Icons.emoji_events_outlined,
  '理财收益': Icons.trending_up_outlined,
  '借入款': Icons.handshake_outlined,
  '其他': Icons.more_horiz,
};
```

- [ ] **Step 2: 实现 `lib/ui/theme.dart`**

```dart
import 'package:flutter/material.dart';

/// 绿色金融主题（与创意方案视觉一致），Material 3
ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
```

- [ ] **Step 3: 实现 `lib/ui/root_tabs.dart`**

```dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/reports_page.dart';
import 'pages/balance_page.dart';
import 'pages/mine_page.dart';

/// 底部 4 Tab 骨架：记账 / 报表 / 资产负债 / 我的
class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomePage(),
    ReportsPage(),
    BalancePage(),
    MinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: '记账'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: '报表'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance),
              label: '资产负债'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 实现 `lib/ui/pages/mine_page.dart`**

```dart
import 'package:flutter/material.dart';

/// 我的：知识模块 v2 占位
class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('财务知识课堂'),
            subtitle: Text('场景化财务知识学习（v2 即将上线）'),
            trailing: Icon(Icons.chevron_right),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: 整体替换 `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'ui/root_tabs.dart';
import 'ui/theme.dart';

void main() {
  runApp(const CaizhiApp());
}

class CaizhiApp extends StatelessWidget {
  const CaizhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..load(),
      child: MaterialApp(
        title: '财智记账',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootTabs(),
      ),
    );
  }
}
```

- [ ] **Step 6: 创建 UI 空壳使编译通过（Task 7/8/9 完整实现前先放最小占位文件）**

`lib/ui/pages/home_page.dart`、`reports_page.dart`、`balance_page.dart` 先各放最小占位：

```dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('记账')));
}
```

（`reports_page.dart` 用 `ReportsPage` + 文本 '报表'，`balance_page.dart` 用 `BalancePage` + 文本 '资产负债'，结构相同。）

- [ ] **Step 7: 静态检查**

```powershell
cd caizhi-app; flutter analyze; cd ..
```

预期：`No issues found!`

- [ ] **Step 8: 提交**

```powershell
git -C caizhi-app add lib
git -C caizhi-app commit -m "feat: 主题、入口与底部导航骨架"
```

### Task 7: 记账流水首页与"记一笔"表单

**Files:**
- Modify: `lib/ui/pages/home_page.dart`（整体替换占位）
- Create: `lib/ui/pages/add_transaction_sheet.dart`

- [ ] **Step 1: 整体替换 `lib/ui/pages/home_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../models/transaction_record.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import 'add_transaction_sheet.dart';

/// 流水首页：月份切换 + 收支汇总卡 + 按日分组流水 + 记一笔
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final records = provider.monthRecords;
    final summary = provider.monthSummary;

    final tiles = <Widget>[];
    String? lastDate;
    for (final r in records) {
      if (r.date != lastDate) {
        lastDate = r.date;
        tiles.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(dayLabel(r.date),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ));
      }
      tiles.add(_TransactionTile(record: r));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('财智记账')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
      body: Column(
        children: [
          _MonthHeader(),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                _SummaryCell(
                    label: '收入', value: summary.income, color: scheme.primary),
                _verticalDivider(scheme),
                _SummaryCell(
                    label: '支出', value: summary.expense, color: scheme.error),
                _verticalDivider(scheme),
                _SummaryCell(
                    label: '结余', value: summary.balance, color: scheme.secondary),
              ]),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        const Text('还没有记录，点右下角记下第一笔吧'),
                      ],
                    ),
                  )
                : ListView(children: tiles),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(ColorScheme scheme) => Container(
        width: 1,
        height: 28,
        color: scheme.outlineVariant,
      );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一月',
          onPressed: () => provider.shiftMonthBy(-1),
        ),
        Text(monthLabel(provider.selectedMonth),
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一月',
          onPressed: () => provider.shiftMonthBy(1),
        ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(fmtMoney(value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionRecord record;

  const _TransactionTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<FinanceProvider>();
    final isIncome = record.type == TxType.income;
    return Dismissible(
      key: ValueKey('tx-${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => provider.deleteTransaction(record.id!),
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(kCategoryIcons[record.category] ?? Icons.receipt_long_outlined,
              size: 20, color: scheme.onPrimaryContainer),
        ),
        title: Text(record.category),
        subtitle: record.note.isEmpty ? null : Text(record.note, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          '${isIncome ? '+' : '-'}${fmtMoney(record.amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isIncome ? scheme.primary : scheme.onSurface,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这笔记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 实现 `lib/ui/pages/add_transaction_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/categories.dart';
import '../../providers/finance_provider.dart';

/// "记一笔"底部弹窗表单：类型 / 分类 / 金额 / 日期 / 备注
Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddTransactionSheet(),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  TxType _type = TxType.expense;
  String? _category;
  DateTime _date = DateTime.now();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<CategoryConfig> get _categories =>
      _type == TxType.expense ? kExpenseCategories : kIncomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final raw = _amountCtrl.text.trim();
    final valid = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw);
    final amount = double.tryParse(raw);
    if (!valid || amount == null || amount <= 0) {
      _toast('请输入大于 0 的金额（最多两位小数）');
      return;
    }
    if (_category == null) {
      _toast('请选择分类');
      return;
    }
    await context.read<FinanceProvider>().addTransaction(
          type: _type,
          category: _category!,
          amount: double.parse(amount.toStringAsFixed(2)),
          date: DateFormat('yyyy-MM-dd').format(_date),
          note: _noteCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(value: TxType.expense, label: Text('支出'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: TxType.income, label: Text('收入'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _category = null;
                }),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _category == c.name,
                      onSelected: (_) => setState(() => _category = c.name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                    labelText: '备注（选填）', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_outlined),
                  const SizedBox(width: 8),
                  Text(DateFormat('yyyy年MM月dd日').format(_date)),
                  const Spacer(),
                  TextButton(onPressed: _pickDate, child: const Text('选择日期')),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 静态检查**

```powershell
cd caizhi-app; flutter analyze; cd ..
```

预期：`No issues found!`（若提示 `_MonthHeader` 需要 const 或 unused 之类，按提示微调。）

- [ ] **Step 4: 提交**

```powershell
git -C caizhi-app add lib
git -C caizhi-app commit -m "feat: 记账流水首页与记一笔表单"
```

### Task 8: 报表页（利润表 / 现金流量表 + 图表）

**Files:**
- Modify: `lib/ui/pages/reports_page.dart`（整体替换占位）

- [ ] **Step 1: 整体替换 `lib/ui/pages/reports_page.dart`**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';
import '../../services/statements.dart';

/// 报表页：利润表 / 现金流量表 两个 Tab
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('报表'),
          bottom: const TabBar(tabs: [Tab(text: '利润表'), Tab(text: '现金流量表')]),
        ),
        body: const TabBarView(children: [_IncomeStatementView(), _CashFlowView()]),
      ),
    );
  }
}

/// 月份切换行（报表页与首页共用 provider.selectedMonth）
class _MonthNav extends StatelessWidget {
  const _MonthNav();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.shiftMonthBy(-1)),
        Text(monthLabel(provider.selectedMonth),
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.shiftMonthBy(1)),
      ],
    );
  }
}

class _IncomeStatementView extends StatelessWidget {
  const _IncomeStatementView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final month = provider.monthSummary;
    final year = provider.yearSummary;
    final trend = provider.trend;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _MonthNav(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('利润表（${monthLabel(month.period)}）',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _StatementRow(
                    label: '收入', value: month.income, color: scheme.primary),
                _StatementRow(label: '支出', value: month.expense, color: scheme.error),
                _StatementRow(
                    label: '结余', value: month.balance, color: scheme.secondary),
                _StatementRow(
                    label: '储蓄率',
                    valueText: '${(month.savingsRate * 100).toStringAsFixed(1)}%',
                    color: scheme.primary),
                const Divider(height: 24),
                Text('本年累计',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                _StatementRow(label: '收入', value: year.income, color: scheme.primary),
                _StatementRow(label: '支出', value: year.expense, color: scheme.error),
                _StatementRow(label: '结余', value: year.balance, color: scheme.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('近 6 个月结余趋势',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: _minY(trend),
                      maxY: _maxY(trend),
                      gridData: const FlGridData(drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${trend[v.toInt()].period.substring(5)}月',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < trend.length; i++)
                              FlSpot(i.toDouble(), trend[i].balance),
                          ],
                          isCurved: true,
                          color: scheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              color: scheme.primary.withValues(alpha: 0.15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _minY(List<PeriodSummary> trend) {
    final values = trend.map((e) => e.balance).toList();
    final m = values.reduce((a, b) => a < b ? a : b);
    return m < 0 ? m * 1.2 : 0;
  }

  double _maxY(List<PeriodSummary> trend) {
    final values = trend.map((e) => e.balance).toList();
    final m = values.reduce((a, b) => a > b ? a : b);
    return m > 0 ? m * 1.2 : 1;
  }
}

class _StatementRow extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueText;
  final Color color;

  const _StatementRow({required this.label, this.value, this.valueText, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(valueText ?? fmtMoney(value ?? 0),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CashFlowView extends StatelessWidget {
  const _CashFlowView();

  static const List<Color> palette = [
    Color(0xFF2E7D32),
    Color(0xFF66BB6A),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFF8E24AA),
    Color(0xFF5C6BC0),
    Color(0xFFC62828),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final cash = provider.cashFlow;
    final byCategory = provider.expenseCategories;
    final total = byCategory.values.fold(0.0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _MonthNav(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('现金流量表（${monthLabel(provider.selectedMonth)}）',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _StatementRow(
                    label: '经营活动净额（日常收支）',
                    value: cash.operating,
                    color: cash.operating >= 0 ? scheme.primary : scheme.error),
                _StatementRow(
                    label: '投资活动净额（买卖理财）',
                    value: cash.investing,
                    color: cash.investing >= 0 ? scheme.primary : scheme.error),
                _StatementRow(
                    label: '筹资活动净额（借入偿还）',
                    value: cash.financing,
                    color: cash.financing >= 0 ? scheme.primary : scheme.error),
                const Divider(height: 24),
                _StatementRow(
                    label: '现金净增加额',
                    value: cash.net,
                    color: scheme.secondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支出分类占比',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                if (total <= 0)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('本月暂无支出记录'),
                  ))
                else ...[
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 48,
                        sectionsSpace: 2,
                        sections: [
                          for (var i = 0; i < byCategory.length; i++)
                            PieChartSectionData(
                              value: byCategory.values.elementAt(i),
                              title:
                                  '${(byCategory.values.elementAt(i) / total * 100).toStringAsFixed(0)}%',
                              radius: 60,
                              color: palette[i % palette.length],
                              titleStyle: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < byCategory.length; i++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 10,
                                height: 10,
                                color: palette[i % palette.length]),
                            const SizedBox(width: 4),
                            Text(
                              '${byCategory.keys.elementAt(i)} ${fmtMoney(byCategory.values.elementAt(i))}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 静态检查**

```powershell
cd caizhi-app; flutter analyze; cd ..
```

预期：`No issues found!`

- [ ] **Step 3: 提交**

```powershell
git -C caizhi-app add lib
git -C caizhi-app commit -m "feat: 利润表与现金流量表页面及图表"
```

### Task 9: 资产负债页

**Files:**
- Modify: `lib/ui/pages/balance_page.dart`（整体替换占位）

- [ ] **Step 1: 整体替换 `lib/ui/pages/balance_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/balance_item.dart';
import '../../providers/finance_provider.dart';
import '../../services/format.dart';

/// 资产负债页：净资产卡 + 资产/负债条目管理
class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final assets = provider.balanceItems.where((i) => i.isAsset).toList();
    final liabilities = provider.balanceItems.where((i) => !i.isAsset).toList();
    final totals = provider.totals;

    return Scaffold(
      appBar: AppBar(title: const Text('资产负债表')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('净资产',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  Text(fmtMoney(totals.netWorth),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      '总资产 ${fmtMoney(totals.assets)} · 总负债 ${fmtMoney(totals.liabilities)}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          _SectionHeader(
              title: '资产（${assets.length}）',
              onAdd: () => _showAddDialog(context, 'asset')),
          if (assets.isEmpty)
            const _EmptyHint(text: '暂无资产条目，点右上角 + 添加'),
          for (final item in assets) _BalanceTile(item: item),
          _SectionHeader(
              title: '负债（${liabilities.length}）',
              onAdd: () => _showAddDialog(context, 'liability')),
          if (liabilities.isEmpty)
            const _EmptyHint(text: '暂无负债条目，点右上角 + 添加'),
          for (final item in liabilities) _BalanceTile(item: item),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, String kind) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kind == 'asset' ? '添加资产' : '添加负债'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: '名称（如：活期存款）', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: '金额', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;

    final raw = amountCtrl.text.trim();
    final valid = RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw);
    final amount = double.tryParse(raw);
    final name = nameCtrl.text.trim();
    if (name.isEmpty || !valid || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名称不能为空，金额需大于 0')));
      return;
    }
    await context.read<FinanceProvider>().addBalanceItem(
        kind: kind, name: name, amount: double.parse(amount.toStringAsFixed(2)));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleSmall)),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      );
}

class _BalanceTile extends StatelessWidget {
  final BalanceItem item;

  const _BalanceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.read<FinanceProvider>();
    return Dismissible(
      key: ValueKey('bi-${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('删除条目'),
          content: Text('确定删除「${item.name}」吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
          ],
        ),
      ),
      onDismissed: (_) => provider.deleteBalanceItem(item.id!),
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      child: ListTile(
        leading: Icon(
            item.isAsset ? Icons.account_balance_wallet_outlined : Icons.credit_card_off_outlined,
            color: item.isAsset ? scheme.primary : scheme.error),
        title: Text(item.name),
        trailing: Text(fmtMoney(item.amount),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

- [ ] **Step 2: 静态检查**

```powershell
cd caizhi-app; flutter analyze; cd ..
```

预期：`No issues found!`

- [ ] **Step 3: 提交**

```powershell
git -C caizhi-app add lib
git -C caizhi-app commit -m "feat: 资产负债表页面与条目管理"
```

### Task 10: 全量校验与格式化

**Files:**
- Modify: 可能触及 `lib/**`、`test/**`（dart format 产生的排版变化）

- [ ] **Step 1: 跑全部单元测试**

```powershell
cd caizhi-app; flutter test; cd ..
```

预期：`All tests passed!`（categories / statements / database 三套测试）

- [ ] **Step 2: lint 与格式化（用户规则：提交前必跑）**

```powershell
cd caizhi-app; flutter analyze; dart format lib test; cd ..
```

预期：analyze `No issues found!`；format 输出 `Formatted N files`。

- [ ] **Step 3: 格式化后再跑一次测试确认未被破坏**

```powershell
cd caizhi-app; flutter test; cd ..
```

预期：`All tests passed!`

- [ ] **Step 4: 提交**

```powershell
git -C caizhi-app add -A
git -C caizhi-app commit -m "style: dart format 全量格式化"
```

### Task 11: 打包 release APK 并交付

**Files:**
- Create: `财智记账-v1.0.0.apk`（工作目录根，交付物）

- [ ] **Step 1: 打包**

```powershell
cd caizhi-app; flutter build apk --release; cd ..
```

预期：末尾出现 `√ Built build\app\outputs\flutter-apk\app-release.apk (XX.XMB)`。

首次打包会下载 Gradle Wrapper 与依赖：
- 若 `services.gradle.org` 下载超时：改 `android/gradle/wrapper/gradle-wrapper.properties` 的 `distributionUrl`，把 `https\://services.gradle.org/distribution/` 替换为 `https\://mirrors.cloud.tencent.com/gradle/`（版本号不变），重跑。
- 若个别依赖在阿里云镜像缺失报错：临时把 `settings.gradle(.kts)` 中 `google()`/`mavenCentral()` 行恢复（镜像行保留在前），重跑。

- [ ] **Step 2: 复制 APK 到工作目录交付**

```powershell
Copy-Item "caizhi-app\build\app\outputs\flutter-apk\app-release.apk" ".\财智记账-v1.0.0.apk" -Force
Get-Item ".\财智记账-v1.0.0.apk" | Select-Object Name, Length
```

预期：文件存在，大小约 20-30MB。

- [ ] **Step 3: 打 tag 记录版本**

```powershell
git -C caizhi-app tag v1.0.0
```

（实施计划文档已在规划阶段提交至 finance-app-proposal 仓库，此处无需重复提交。）

- [ ] **Step 4: （可选，需用户确认）上传 GitHub Release**

用 `gh release create` 把 APK 传到 `lie310225/caizhi-jizhang` 的 v1.1.0 Release（资产名用 ASCII：`caizhi-jizhang-v1.0.0.apk`）。网络不稳时加 `git -c http.version=HTTP/1.1`；上传大文件失败可重试或改为网盘分发。

---

## 验收清单（spec → 任务映射）

| 设计要求 | 对应任务 |
| -------- | -------- |
| 记一笔（类型/金额/分类/日期/备注） | Task 7 |
| 流水按月分组 + 月汇总 + 月份切换 | Task 7 |
| 利润表（月/年、储蓄率） | Task 4 + Task 8 |
| 现金流量表三分法 | Task 2 + Task 4 + Task 8 |
| 资产负债表 + 净资产 | Task 4 + Task 9 |
| 知识模块入口占位 | Task 6 |
| 本地 SQLite 存储 | Task 3 |
| Material 3 绿色主题、移动优先 | Task 6 |
| 金额校验/删除确认/空状态 | Task 7 + Task 9 |
| 报表聚合单测 | Task 2/3/4 测试 |
| release APK 交付 | Task 11 |






