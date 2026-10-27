import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import '../models/transaction_record.dart';
import '../models/balance_item.dart';

/// UTF-8 BOM，Excel 打开中文不乱码
const List<int> _bom = [0xEF, 0xBB, 0xBF];

String _escapeCsvField(String s) {
  final q = s.replaceAll('"', '""');
  return (q.contains(',') || q.contains('"') || q.contains('\n')) ? '"$q"' : q;
}

String _transactionsHeader() =>
    'id,type,category,amount,flow,date,note,created_at';

String _balanceHeader() => 'id,kind,name,amount,updated_at';

List<int> transactionsToCsv(List<TransactionRecord> records) {
  final buf = StringBuffer('${_transactionsHeader()}\n');
  for (final r in records) {
    buf.writeln(
      [
        r.id ?? '',
        r.type.name,
        _escapeCsvField(r.category),
        r.amount.toString(),
        r.flow.name,
        _escapeCsvField(r.date),
        _escapeCsvField(r.note),
        _escapeCsvField(r.createdAt),
      ].join(','),
    );
  }
  return [..._bom, ...utf8.encode(buf.toString())];
}

List<int> balanceItemsToCsv(List<BalanceItem> items) {
  final buf = StringBuffer('${_balanceHeader()}\n');
  for (final b in items) {
    buf.writeln(
      [
        b.id ?? '',
        _escapeCsvField(b.kind),
        _escapeCsvField(b.name),
        b.amount.toString(),
        _escapeCsvField(b.updatedAt),
      ].join(','),
    );
  }
  return [..._bom, ...utf8.encode(buf.toString())];
}

Future<List<int>> csvZipData(
  List<TransactionRecord> records,
  List<BalanceItem> items,
) async {
  final txCsv = transactionsToCsv(records);
  final baCsv = balanceItemsToCsv(items);
  final a = Archive()
    ..addFile(ArchiveFile('transactions.csv', txCsv.length, txCsv))
    ..addFile(ArchiveFile('balance_items.csv', baCsv.length, baCsv));
  return ZipEncoder().encode(a)!;
}

String defaultZipFileName() =>
    'caizhi-export-${DateFormat('yyyyMMdd').format(DateTime.now())}.zip';
