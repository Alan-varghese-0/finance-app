import 'package:finance_app/features/analysis/services/insight_generator.dart';
import 'package:finance_app/features/analysis/widget/insight_title.dart';
import 'package:flutter/material.dart';
import '../../expenses/models/expense.dart';

class SmartInsights extends StatelessWidget {
  final List<Expense> expenses;

  const SmartInsights({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final insights = generateInsights(expenses);

    if (insights.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...insights.map((insight) => InsightTile(insight: insight)),
      ],
    );
  }
}
