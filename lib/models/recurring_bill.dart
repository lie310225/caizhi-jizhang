import '../config/categories.dart';

/// 周期账单模板：每月固定日期的一笔收支，到期后一键记入流水
class RecurringBill {
  final int? id;
  final String title;
  final String category;
  final TxType type;
  final double amount;
  final int dayOfMonth; // 1-28
  final bool active;
  final String lastAppliedMonth; // yyyy-MM，空串表示从未记账

  const RecurringBill({
    this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.dayOfMonth,
    this.active = true,
    this.lastAppliedMonth = '',
  });

  RecurringBill copyWith({
    int? id,
    String? title,
    String? category,
    TxType? type,
    double? amount,
    int? dayOfMonth,
    bool? active,
    String? lastAppliedMonth,
  }) => RecurringBill(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    active: active ?? this.active,
    lastAppliedMonth: lastAppliedMonth ?? this.lastAppliedMonth,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'type': type.name,
    'amount': amount,
    'day_of_month': dayOfMonth,
    'active': active ? 1 : 0,
    'last_applied_month': lastAppliedMonth,
  };

  factory RecurringBill.fromMap(Map<String, Object?> map) => RecurringBill(
    id: map['id'] as int?,
    title: map['title'] as String,
    category: map['category'] as String,
    type: TxType.values.byName(map['type'] as String),
    amount: (map['amount'] as num).toDouble(),
    dayOfMonth: map['day_of_month'] as int,
    active: (map['active'] as int? ?? 1) == 1,
    lastAppliedMonth: (map['last_applied_month'] as String?) ?? '',
  );
}
