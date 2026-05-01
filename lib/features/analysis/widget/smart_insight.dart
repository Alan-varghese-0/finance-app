import 'package:flutter/material.dart';

class SmartInsights extends StatelessWidget {
  const SmartInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        InsightTile("You spent 25% more this week"),
        InsightTile("Friday is your highest spending day"),
        InsightTile("Subscriptions increased by ₹300"),
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
      child: ListTile(leading: const Icon(Icons.insights), title: Text(text)),
    );
  }
}
