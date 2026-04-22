import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../data/categories.dart';
import '../models/category.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  /// 🔥 GROUP BY CATEGORY AND TYPE
  Map<String, Map<TransactionType, double>> getCategoryTotals() {
    final Map<String, Map<TransactionType, double>> data = {};

    for (var e in expenses) {
      data[e.category] ??= {
        TransactionType.expense: 0,
        TransactionType.income: 0,
      };
      data[e.category]![e.type] = (data[e.category]![e.type] ?? 0) + e.amount;
    }

    return data;
  }

  /// 🔥 GET CATEGORY MODEL
  CategoryModel getCategory(String name) {
    return categories.firstWhere(
      (c) => c.name == name,
      orElse: () => categories.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = getCategoryTotals();
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No transaction data"),
      );
    }

    // Flatten for chart: show both incomes and expenses as separate pie slices
    final chartEntries = <Map<String, dynamic>>[];
    double total = 0;
    data.forEach((category, typeMap) {
      typeMap.forEach((type, amount) {
        if (amount > 0) {
          chartEntries.add({
            'category': category,
            'type': type,
            'amount': amount,
          });
          total += amount;
        }
      });
    });

    if (chartEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No transaction data"),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: Column(
        children: [
          /// 🔥 PIE CHART
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: chartEntries.map((entry) {
                  final category = getCategory(entry['category'] as String);
                  final value = entry['amount'] as double;
                  final percent = (value / total) * 100;
                  final type = entry['type'] as TransactionType;
                  // Use a different shade for income vs expense
                  final baseColor = Color(category.color);
                  final color = type == TransactionType.expense
                      ? baseColor
                      : baseColor.withOpacity(0.6);
                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: "${percent.toStringAsFixed(0)}%",
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 LEGEND
          Column(
            children: chartEntries.map((entry) {
              final category = getCategory(entry['category'] as String);
              final type = entry['type'] as TransactionType;
              final value = entry['amount'] as double;
              final baseColor = Color(category.color);
              final color = type == TransactionType.expense
                  ? baseColor
                  : baseColor.withOpacity(0.6);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    /// COLOR DOT
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// NAME + TYPE
                    Expanded(
                      child: Text(
                        "${category.name} (${type == TransactionType.expense ? 'Expense' : 'Income'})",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    /// AMOUNT
                    Text(
                      "₹${value.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
