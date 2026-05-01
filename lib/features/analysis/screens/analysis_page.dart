import 'package:finance_app/features/analysis/widget/bar_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/line_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/pie_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/smart_insight.dart';
import 'package:finance_app/features/analysis/widget/split_insight.dart';
import 'package:finance_app/features/analysis/widget/subscribtion_insight.dart';
import 'package:finance_app/features/analysis/widget/summery_card.dart';
import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analysis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            SummaryCards(),
            SizedBox(height: 20),
            PieChartWidget(),
            SizedBox(height: 20),
            LineChartWidget(),
            SizedBox(height: 20),
            BarChartWidget(),
            SizedBox(height: 20),
            SubscriptionInsights(),
            SizedBox(height: 20),
            SplitInsights(),
            SizedBox(height: 20),
            SmartInsights(),
          ],
        ),
      ),
    );
  }
}
