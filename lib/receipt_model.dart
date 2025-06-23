class Receipt {
  final int id;
  final String store;
  final String date;
  final String amount;
  final String? createdAt;

  Receipt({
    required this.id,
    required this.store,
    required this.date,
    required this.amount,
    this.createdAt,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      store: map['store'] ?? '',
      date: map['date'] ?? '',
      amount: map['amount'] ?? '',
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store': store,
      'date': date,
      'amount': amount,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'Receipt(id: $id, store: $store, date: $date, amount: $amount)';
  }

  Receipt copyWith({
    int? id,
    String? store,
    String? date,
    String? amount,
    String? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      store: store ?? this.store,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 