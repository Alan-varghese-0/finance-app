import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class SmartInsights extends StatelessWidget {
  const SmartInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        InsightTile("📈 You spent 25% more this week"),
        InsightTile("🔥 Friday is highest spending day"),
        InsightTile("⚠️ Subscriptions increased ₹300"),
      ],
    );
  }
}

class InsightTile extends StatelessWidget {
  final String text;
  const InsightTile(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.auto_graph, color: AppColors.primary),
        title: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
