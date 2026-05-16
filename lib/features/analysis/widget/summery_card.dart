import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../data/repositories/firestore_user.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  Future<Map<String, dynamic>> _fetchSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return {'balance': 0.0, 'expense': 0.0, 'income': 0.0};
    }

    /// USER DOC
    final userDoc = await UserFirestore(uid).userDoc.get();

    final balance = ((userDoc.data()?['balance'] ?? 0.0) as num).toDouble();

    /// EXPENSES
    final expensesSnap = await UserFirestore(uid).expenses.get();

    double totalExpense = 0.0;
    double totalIncome = 0.0;

    for (var doc in expensesSnap.docs) {
      final data = doc.data();

      final amount = ((data['amount'] ?? 0.0) as num).toDouble();

      final type = data['type'] ?? 'expense';

      if (type == 'expense') {
        totalExpense += amount;
      } else if (type == 'income') {
        totalIncome += amount;
      }
    }

    return {'balance': balance, 'expense': totalExpense, 'income': totalIncome};
  }

  /// SHORT FORMAT
  String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  /// FULL FORMAT
  String fullAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  void _showAmountPopup(
    BuildContext context,
    String title,
    double amount,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          fullAmount(amount),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
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
              _card(context, "Balance", data['balance'], AppColors.primary),

              const SizedBox(width: 8),

              _card(context, "Expense", data['expense'], AppColors.expense),

              const SizedBox(width: 8),

              _card(context, "Income", data['income'], AppColors.income),
            ],
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, String title, double amount, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showAmountPopup(context, title, amount, color),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.9), color]),

            borderRadius: BorderRadius.circular(16),

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
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              /// VALUE
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatAmount(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
