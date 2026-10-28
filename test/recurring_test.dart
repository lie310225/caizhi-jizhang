import 'package:flutter_test/flutter_test.dart';
import 'package:finance/config/categories.dart';
import 'package:finance/models/recurring_bill.dart';
import 'package:finance/services/recurring.dart';

RecurringBill _bill({
  int? id,
  String title = '房租',
  int day = 5,
  bool active = true,
  String lastAppliedMonth = '',
}) => RecurringBill(
  id: id,
  title: title,
  category: '居住',
  type: TxType.expense,
  amount: 3000,
  dayOfMonth: day,
  active: active,
  lastAppliedMonth: lastAppliedMonth,
);

void main() {
  group('周期账单到期判断', () {
    const today = '2026-10-20';

    test('本月未到日号时不到期', () {
      expect(
        isRecurringDue(_bill(day: 25), month: '2026-10', today: today),
        isFalse,
      );
    });

    test('本月已过日号则到期', () {
      expect(
        isRecurringDue(_bill(day: 5), month: '2026-10', today: today),
        isTrue,
      );
    });

    test('本月已记过不再到期', () {
      expect(
        isRecurringDue(
          _bill(day: 5, lastAppliedMonth: '2026-10'),
          month: '2026-10',
          today: today,
        ),
        isFalse,
      );
    });

    test('停用账单不到期', () {
      expect(
        isRecurringDue(
          _bill(day: 5, active: false),
          month: '2026-10',
          today: today,
        ),
        isFalse,
      );
    });

    test('过去月份全部视为到期，未来月份不到期', () {
      expect(
        isRecurringDue(_bill(day: 28), month: '2026-09', today: today),
        isTrue,
      );
      expect(
        isRecurringDue(_bill(day: 1), month: '2026-11', today: today),
        isFalse,
      );
    });
  });

  test('到期列表按日号升序', () {
    final due = dueRecurrings(
      [
        _bill(id: 1, title: '会员', day: 12),
        _bill(id: 2, title: '房租', day: 1),
        _bill(id: 3, title: '未来', day: 26),
      ],
      month: '2026-10',
      today: '2026-10-20',
    );
    expect(due.map((b) => b.title), ['房租', '会员']);
  });

  test('记账日期取当月对应日号', () {
    expect(recurringDate(_bill(day: 5), '2026-10'), '2026-10-05');
  });

  test('日号超出当月天数时取月末', () {
    expect(recurringDate(_bill(day: 31), '2026-02'), '2026-02-28');
    expect(recurringDate(_bill(day: 31), '2026-04'), '2026-04-30');
  });
}
