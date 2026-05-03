import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../theme/theme.dart';

/// 📊 Model
class MonthlyChartData {
  final double day;
  final double income;
  final double expense;

  MonthlyChartData(this.day, this.income, this.expense);
}

class LineChartWidget extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> expenseCollection;

  const LineChartWidget({super.key, required this.expenseCollection});

  Stream<List<MonthlyChartData>> getMonthlyData() {
    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return expenseCollection
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThan: endOfMonth)
        .snapshots()
        .map((snapshot) {
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

          List<double> incomeTotals = List.filled(daysInMonth, 0);
          List<double> expenseTotals = List.filled(daysInMonth, 0);

          for (var doc in snapshot.docs) {
            final data = doc.data();

            final amount = (data['amount'] ?? 0).toDouble();
            final date = (data['date'] as Timestamp).toDate();
            final type = data['type']; // "income" or "expense"

            int index = date.day - 1;

            if (type == 'income') {
              incomeTotals[index] += amount;
            } else {
              expenseTotals[index] += amount;
            }
          }

          return List.generate(
            daysInMonth,
            (i) => MonthlyChartData(
              (i + 1).toDouble(),
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
      child: StreamBuilder<List<MonthlyChartData>>(
        stream: getMonthlyData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return SfCartesianChart(
            tooltipBehavior: TooltipBehavior(enable: true),

            /// 🔥 Legend
            legend: const Legend(
              isVisible: true,
              textStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              position: LegendPosition.bottom,
            ),

            primaryXAxis: NumericAxis(
              interval: 5,
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
              /// 💚 Income Line
              LineSeries<MonthlyChartData, double>(
                name: 'Income',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.income,
                color: const Color(0xFF22C55E),
                width: 3,
                markerSettings: const MarkerSettings(isVisible: true),
                animationDuration: 800,
              ),

              /// ❤️ Expense Line
              LineSeries<MonthlyChartData, double>(
                name: 'Expense',
                dataSource: data,
                xValueMapper: (d, _) => d.day,
                yValueMapper: (d, _) => d.expense,
                color: const Color(0xFFEF4444),
                width: 3,
                markerSettings: const MarkerSettings(isVisible: true),
                animationDuration: 800,
              ),
            ],
          );
        },
      ),
    );
  }
}
