import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../data/firestore_user.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  Future<Map<String, dynamic>> _fetchSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'balance': 0.0, 'expense': 0.0, 'income': 0.0};

    final userDoc = await UserFirestore(uid).userDoc.get();
    final initialAmount = (userDoc.data()?['balance'] ?? 0.0) as num;

    final expensesSnap = await UserFirestore(uid).expenses.get();
    double totalExpense = 0.0;
    double totalIncome = 0.0;
    for (var doc in expensesSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] ?? 0.0) as num;
      final type = data['type'] ?? 'expense';
      if (type == 'expense') {
        totalExpense += amount;
      } else if (type == 'income') {
        totalIncome += amount;
      }
    }

    final balance = initialAmount + totalIncome - totalExpense;
    return {'balance': balance, 'expense': totalExpense, 'income': totalIncome};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchSummary(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? {'balance': 0.0, 'expense': 0.0, 'income': 0.0};
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _card(
                "Balance",
                "₹${data['balance'].toStringAsFixed(2)}",
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _card(
                "Expense",
                "₹${data['expense'].toStringAsFixed(2)}",
                AppColors.expense,
              ),
              const SizedBox(width: 8),
              _card(
                "Income",
                "₹${data['income'].toStringAsFixed(2)}",
                AppColors.income,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.9), color]),
          borderRadius: BorderRadius.circular(16),

          /// 🔥 subtle depth (matches modern fintech apps)
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70, // ✅ better contrast
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            /// VALUE
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // ✅ crisp on gradient
              ),
            ),
          ],
        ),
      ),
    );
  }
}
