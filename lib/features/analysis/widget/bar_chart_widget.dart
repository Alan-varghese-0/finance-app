import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:finance_app/theme/theme.dart';

/// 📊 Model
class WeeklyChartData {
  final String day;
  final double income;
  final double expense;

  WeeklyChartData(this.day, this.income, this.expense);
}

class BarChartWidget extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> expenseCollection;

  const BarChartWidget({super.key, required this.expenseCollection});

  /// 🔥 Weekly Data Stream (FIXED)
  Stream<List<WeeklyChartData>> getWeeklyData() {
    return expenseCollection.snapshots().map((snapshot) {
      List<double> incomeTotals = List.filled(7, 0);
      List<double> expenseTotals = List.filled(7, 0);

      final now = DateTime.now();

      /// ✅ Normalize today
      final today = DateTime(now.year, now.month, now.day);

      /// ✅ Start of week (Monday)
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      /// ✅ End of week (exclusive)
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final amount = (data['amount'] ?? 0).toDouble();

        /// ✅ Normalize date
        final rawDate = (data['date'] as Timestamp).toDate();
        final date = DateTime(rawDate.year, rawDate.month, rawDate.day);

        /// ✅ Normalize type
        final type = (data['type'] ?? '').toString().toLowerCase().trim();

        /// ✅ Filter only current week
        if (date.isBefore(startOfWeek) || !date.isBefore(endOfWeek)) {
          continue;
        }

        final index = date.weekday - 1;

        if (type == 'income') {
          incomeTotals[index] += amount;
        } else if (type == 'expense') {
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
      height: 240,
      child: StreamBuilder<List<WeeklyChartData>>(
        stream: getWeeklyData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          /// 🔥 Check empty
          final hasData = data.any((e) => e.income > 0 || e.expense > 0);

          if (!hasData) {
            return const Center(
              child: Text(
                "No data this week",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          /// 🔥 FIX: Calculate max value for scaling
          double maxValue = 0;
          for (var d in data) {
            if (d.income > maxValue) maxValue = d.income;
            if (d.expense > maxValue) maxValue = d.expense;
          }

          if (maxValue == 0) maxValue = 100;

          /// 🔥 Add padding
          final chartMax = maxValue * 1.2;

          return SfCartesianChart(
            tooltipBehavior: TooltipBehavior(enable: true),

            /// 🔥 Legend
            legend: const Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              textStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            /// X Axis
            primaryXAxis: CategoryAxis(
              labelStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              majorGridLines: const MajorGridLines(width: 0),
            ),

            /// 🔥 FIXED Y AXIS
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: chartMax,
              interval: chartMax / 5,
              labelStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
            ),

            series: [
              /// 💚 Income
              ColumnSeries<WeeklyChartData, String>(
                name: 'Income',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.income,
                color: const Color(0xFF22C55E),
                width: 0.45,
                spacing: 0.2,
                borderRadius: BorderRadius.circular(6),
                animationDuration: 800,
              ),

              /// ❤️ Expense
              ColumnSeries<WeeklyChartData, String>(
                name: 'Expense',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.expense,
                color: const Color(0xFFEF4444),
                width: 0.45,
                spacing: 0.2,
                borderRadius: BorderRadius.circular(6),
                animationDuration: 800,
              ),
            ],
          );
        },
      ),
    );
  }
}
