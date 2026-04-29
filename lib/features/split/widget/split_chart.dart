import 'package:flutter/material.dart';

class SplitChart extends StatelessWidget {
  const SplitChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text("Split Chart (Coming Soon)")),
    );
  }
}
