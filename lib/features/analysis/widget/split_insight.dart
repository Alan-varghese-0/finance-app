import 'package:flutter/material.dart';

class SplitInsights extends StatelessWidget {
  const SplitInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return _card("Split", "You owe ₹500\nAlex owes you ₹1200");
  }

  Widget _card(String title, String content) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(content)),
    );
  }
}
