import 'package:finance_app/features/analysis/model/model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: MockData.categories.map((e) {
            return PieChartSectionData(value: e.amount, title: e.name);
          }).toList(),
        ),
      ),
    );
  }
}
