import 'package:flutter/material.dart';

class SplitLegend extends StatelessWidget {
  const SplitLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ListTile(
          leading: Icon(Icons.arrow_upward, color: Colors.red),
          title: Text("You owe ₹500"),
        ),
        ListTile(
          leading: Icon(Icons.arrow_downward, color: Colors.green),
          title: Text("You get ₹1200"),
        ),
      ],
    );
  }
}
