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

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
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
  TransactionRecord copyWith({
    int? id,
    TxType? type,
    String? category,
    double? amount,
    FlowType? flow,
    String? date,
    String? note,
  }) => TransactionRecord(
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
