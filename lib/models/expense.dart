class Expense {
  final int? id;
  final double amount;
  final String date;
  final String? store;
  final String? items;
  final String category; // Tambahan untuk fitur kategori

  Expense({
    this.id,
    required this.amount,
    required this.date,
    this.store,
    this.items,
    this.category = "Lainnya", // Default kategori jika tidak diisi
  });

  // Mengubah objek Dart ke Map untuk disimpan di SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date,
      'store': store ?? "Toko",
      'items': items ?? "",
      'category': category,
    };
  }

  // Mengubah Map dari SQLite kembali menjadi objek Dart
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      store: map['store'] as String?,
      items: map['items'] as String?,
      category: map['category'] as String? ?? "Lainnya",
    );
  }
}