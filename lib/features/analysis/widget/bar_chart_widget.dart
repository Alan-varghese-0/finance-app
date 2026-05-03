import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finance_app/theme/theme.dart';

/// 📊 Model for chart
class WeeklyChartData {
  final String day;
  final double income;
  final double expense;

  WeeklyChartData(this.day, this.income, this.expense);
}

class BarChartWidget extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> expenseCollection;

  const BarChartWidget({super.key, required this.expenseCollection});

  /// 🔥 Firestore → Weekly grouped data
  Stream<List<WeeklyChartData>> getWeeklyData() {
    return expenseCollection.snapshots().map((
      snapshot,
    ) {
      List<double> incomeTotals = List.filled(7, 0);
      List<double> expenseTotals = List.filled(7, 0);

      final now = DateTime.now();

      /// Start of week (Monday 00:00)
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      /// End of week
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final amount = (data['amount'] ?? 0).toDouble();
        final date = (data['date'] as Timestamp).toDate();
        final type = data['type']; // "income" or "expense"

        /// ✅ Filter current week only
        if (date.isBefore(startOfWeek) || date.isAfter(endOfWeek)) continue;

        int index = date.weekday - 1;

        if (type == 'income') {
          incomeTotals[index] += amount;
        } else {
          expenseTotals[index] += amount;
        }
      }

      return List.generate(
        7,
        (i) => WeeklyChartData(
          ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][i],
          incomeTotals[i],
          expenseTotals[i],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: StreamBuilder<List<WeeklyChartData>>(
        stream: getWeeklyData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return SfCartesianChart(
            tooltipBehavior: TooltipBehavior(enable: true),

            /// 🔥 Legend (Income / Expense)
            legend: const Legend(
              isVisible: true,
              textStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              position: LegendPosition.bottom,
            ),

            primaryXAxis: CategoryAxis(
              labelStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              majorGridLines: const MajorGridLines(width: 0),
            ),

            primaryYAxis: NumericAxis(
              labelStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
            ),

            series: [
              /// 💚 Income Bars
              ColumnSeries<WeeklyChartData, String>(
                name: 'Income',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.income,
                color: const Color(0xFF22C55E), // green
                width: 0.50,
                spacing: 0.2,
                borderRadius: BorderRadius.circular(8),
                animationDuration: 800,
              ),

              /// ❤️ Expense Bars
              ColumnSeries<WeeklyChartData, String>(
                name: 'Expense',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.expense,
                color: const Color(0xFFEF4444), // red
                width: 0.50,
                spacing: 0.2,
                borderRadius: BorderRadius.circular(8),
                animationDuration: 800,
              ),
            ],
          );
        },
      ),
    );
  }
}
