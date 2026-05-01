import 'package:finance_app/features/analysis/model/model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: MockData.weeklySpending
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(toY: e.value)],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
