import 'package:finance_app/features/analysis/model/model.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class InsightTile extends StatelessWidget {
  final Insight insight;

  const InsightTile({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: insight.color.withOpacity(0.1),
          child: Icon(insight.icon, color: insight.color),
        ),
        title: Text(
          insight.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
