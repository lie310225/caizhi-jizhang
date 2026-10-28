/// 月度预算条目：category 为 [totalCategory] 时代表整月总预算
class Budget {
  final int? id;
  final String month; // yyyy-MM
  final String category;
  final double amount;

  const Budget({
    this.id,
    required this.month,
    required this.category,
    required this.amount,
  });

  /// 总预算使用的分类键（空串，避免与真实分类重名）
  static const String totalCategory = '';

  bool get isTotal => category == totalCategory;

  Map<String, Object?> toMap() => {
    'id': id,
    'month': month,
    'category': category,
    'amount': amount,
  };

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
    id: map['id'] as int?,
    month: map['month'] as String,
    category: map['category'] as String,
    amount: (map['amount'] as num).toDouble(),
  );
}
