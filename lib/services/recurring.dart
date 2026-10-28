import '../models/recurring_bill.dart';

/// 当前日期字符串 yyyy-MM-dd
String todayString([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 某月在「今天」视角下的状态：已经过去 / 就是本月 / 未来
int _monthRelation(String month, String today) {
  final current = today.substring(0, 7);
  return month.compareTo(current);
}

/// 账单在指定月份是否到期可记：已启用、本月未记过、且已到该日
bool isRecurringDue(
  RecurringBill bill, {
  required String month,
  required String today,
}) {
  if (!bill.active || bill.lastAppliedMonth == month) return false;
  final relation = _monthRelation(month, today);
  if (relation < 0) return true; // 过去的月份视作全部已到日
  if (relation > 0) return false; // 未来月份还不到
  final todayDay = int.parse(today.substring(8, 10));
  return bill.dayOfMonth <= todayDay;
}

/// 指定月份所有到期账单，按日号升序
List<RecurringBill> dueRecurrings(
  List<RecurringBill> bills, {
  required String month,
  required String today,
}) {
  final result = bills
      .where((b) => isRecurringDue(b, month: month, today: today))
      .toList();
  result.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
  return result;
}

/// 账单对应的记账日期：month + dayOfMonth，日号超出当月天数时取月末
String recurringDate(RecurringBill bill, String month) {
  final year = int.parse(month.substring(0, 4));
  final mon = int.parse(month.substring(5, 7));
  final lastDay = DateTime(year, mon + 1, 0).day;
  final day = bill.dayOfMonth > lastDay ? lastDay : bill.dayOfMonth;
  return '$month-${day.toString().padLeft(2, '0')}';
}
