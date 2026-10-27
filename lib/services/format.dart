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
