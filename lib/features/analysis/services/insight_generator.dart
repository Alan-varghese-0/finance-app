import 'package:finance_app/features/analysis/model/model.dart';
import 'package:flutter/material.dart';
import '../../expenses/models/expense.dart';

List<Insight> generateInsights(List<Expense> expenses) {
  if (expenses.isEmpty) return [];

  final now = DateTime.now();
  final lastWeek = now.subtract(const Duration(days: 7));

  final thisWeekExpenses = expenses
      .where((e) => e.date.isAfter(lastWeek))
      .toList();

  final prevWeekExpenses = expenses.where((e) {
    return e.date.isBefore(lastWeek) &&
        e.date.isAfter(lastWeek.subtract(const Duration(days: 7)));
  }).toList();

  double sum(List<Expense> list) =>
      list.fold(0, (total, e) => total + e.amount);

  final thisWeekTotal = sum(thisWeekExpenses);
  final prevWeekTotal = sum(prevWeekExpenses);

  List<Insight> insights = [];

  // 📈 Weekly comparison
  if (prevWeekTotal > 0) {
    final change = ((thisWeekTotal - prevWeekTotal) / prevWeekTotal) * 100;

    if (change > 0) {
      insights.add(
        Insight(
          text: "You spent ${change.toStringAsFixed(0)}% more this week",
          icon: Icons.trending_up,
          color: Colors.red,
        ),
      );
    } else {
      insights.add(
        Insight(
          text: "You reduced spending by ${change.abs().toStringAsFixed(0)}%",
          icon: Icons.trending_down,
          color: Colors.green,
        ),
      );
    }
  }

  // 🔥 Highest spending day
  final Map<int, double> dayTotals = {};
  for (var e in expenses) {
    dayTotals[e.date.weekday] = (dayTotals[e.date.weekday] ?? 0) + e.amount;
  }

  if (dayTotals.isNotEmpty) {
    final highestDay = dayTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    const days = [
      "",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    insights.add(
      Insight(
        text: "${days[highestDay]} is your highest spending day",
        icon: Icons.local_fire_department,
        color: Colors.orange,
      ),
    );
  }

  // 💰 Total spending insight
  if (thisWeekTotal > 0) {
    insights.add(
      Insight(
        text: "You spent ₹${thisWeekTotal.toStringAsFixed(0)} this week",
        icon: Icons.account_balance_wallet,
        color: Colors.blue,
      ),
    );
  }

  return insights;
}
