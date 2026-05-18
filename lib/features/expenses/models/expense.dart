enum TransactionType { income, expense }

class Expense {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String source; // 🔥 NEW (expense / subscription / split)
  final String location; // 📍 NEW (location where expense occurred)
  final String? receiptUrl; // 📸 Receipt/image URL

  Expense({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.source,
    this.location = 'Not specified',
    this.receiptUrl,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    return Expense(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as dynamic).toDate(),
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: data['category'] ?? 'General',
      source: "expense", // ✅ default
      location: data['location'] ?? data['locationAddress'] ?? 'Not specified',
      receiptUrl: data['receiptUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'date': date,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': category,
      'location': location,
    };
  }
}
