enum TransactionType { income, expense }

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category; // ✅ ADD THIS

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category, // ✅ ADD THIS
  });

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      title: data['title'] ?? "No Title",
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] != null ? (data['date']).toDate() : DateTime.now(),
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,

      category: data['category'] ?? "General", // ✅ ADD THIS
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': date,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category, // ✅ ADD THIS
    };
  }
}
