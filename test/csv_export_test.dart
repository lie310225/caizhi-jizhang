import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance/config/categories.dart';
import 'package:finance/models/transaction_record.dart';
import 'package:finance/models/balance_item.dart';
import 'package:finance/services/csv_export.dart';

void main() {
  final r = TransactionRecord(
    id: 1,
    type: TxType.expense,
    category: '餐饮',
    amount: 25.5,
    flow: FlowType.operating,
    date: '2026-10-27',
    note: '有"引号",带逗号',
    createdAt: '2026-10-27T12:00:00',
  );
  final b = const BalanceItem(
    id: 1,
    kind: 'asset',
    name: '活期存款',
    amount: 12000,
    updatedAt: '2026-10-27T09:00:00',
  );

  test('transactions CSV 包含 UTF-8 BOM', () {
    final csv = transactionsToCsv([r]);
    expect(csv[0], 0xEF);
    expect(csv[1], 0xBB);
    expect(csv[2], 0xBF);
  });

  test('note 中引号加倍 + 逗号用双引号包裹', () {
    final csv = utf8.decode(transactionsToCsv([r]));
    // 内部引号加倍为 ""，整个字段因含逗号被外层双引号包裹
    // 实际字段值："有""引号"",带逗号"
    expect(csv, contains('""')); // 引号已加倍
    expect(csv, contains('"有')); // 外层左引号
    expect(csv, contains('号"')); // 外层右引号在逗号前
    expect(csv, contains(',带逗号')); // 逗号留在引号内
  });

  test('空记录生成只有表头的 CSV', () {
    final csv = utf8.decode(transactionsToCsv([]));
    expect(csv.split('\n').length, greaterThanOrEqualTo(2)); // 表头 + 空行
    expect(csv, contains('id,type,category,amount,flow,date,note,created_at'));
  });

  test('balance_items CSV 结构正确', () {
    final csv = utf8.decode(balanceItemsToCsv([b]));
    expect(csv, contains('id,kind,name,amount,updated_at'));
    expect(csv, contains('1,asset,活期存款,12000.0,2026-10-27T09:00:00'));
  });

  test('zip 包含两份 CSV 文件名正确', () async {
    final zip = await csvZipData([r], [b]);
    expect(zip.length, greaterThan(0));
    // archive 包解析 zip 验证文件名
    final decoded = ZipDecoder().decodeBytes(zip);
    final names = decoded.map((e) => e.name).toSet();
    expect(names, contains('transactions.csv'));
    expect(names, contains('balance_items.csv'));
  });
}
