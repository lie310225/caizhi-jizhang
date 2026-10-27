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
