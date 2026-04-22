import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SplitDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot data;

  const SplitDetailsSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List people = data['people'] ?? [];
    final List owes = data['owe'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['title'] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Text("Total: ₹${data['amount']}"),

          const Divider(),

          /// 👥 PEOPLE
          ...people.map((p) {
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(p['name']),
              trailing: Text("₹${p['amount']}"),
            );
          }),

          const Divider(),

          /// 💥 OWE BREAKDOWN
          ...owes.map((o) {
            return ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text("${o['from']} owes ${o['to']}"),
              trailing: Text("₹${o['amount']}"),
            );
          }),
        ],
      ),
    );
  }
}
