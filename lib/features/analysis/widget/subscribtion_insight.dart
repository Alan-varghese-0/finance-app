import 'package:flutter/material.dart';

class SubscriptionInsights extends StatelessWidget {
  const SubscriptionInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return _card("Subscriptions", "₹1200/month\nNext renewal: Netflix");
  }

  Widget _card(String title, String content) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(content)),
    );
  }
}
