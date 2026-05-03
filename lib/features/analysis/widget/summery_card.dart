import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _card("Balance", "₹12,000", AppColors.primary),
          const SizedBox(width: 8),
          _card("Expense", "₹8,500", AppColors.expense),
          const SizedBox(width: 8),
          _card("Income", "₹20,000", AppColors.income),
        ],
      ),
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
