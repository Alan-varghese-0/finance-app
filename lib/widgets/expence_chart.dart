import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/theme.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    double income = 0;
    double expense = 0;

    for (var e in expenses) {
      if (e.type == TransactionType.income) {
        income += e.amount;
      } else {
        expense += e.amount;
      }
    }

    final balance = income - expense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),

        // ✅ FIX: Use border instead of shadow
        border: Border.all(color: AppColors.border, width: 1),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          /// CHART
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    startDegreeOffset: -90,

                    sections: [
                      PieChartSectionData(
                        value: income == 0 ? 1 : income,
                        color: AppColors.income,
                        radius: 55,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: expense == 0 ? 1 : expense,
                        color: AppColors.expense,
                        radius: 55,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),

                /// CENTER INFO
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Balance",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${balance.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// LEGEND
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem("Income", income, AppColors.income),
              _legendItem("Expense", expense, AppColors.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String title, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              "₹${value.toStringAsFixed(0)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
