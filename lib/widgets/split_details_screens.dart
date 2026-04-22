import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SplitDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot data;

  const SplitDetailsSheet({super.key, required this.data});

  /// 🔥 CALCULATE BALANCES
  List<Map<String, dynamic>> calculateBalances(List people) {
    double total = 0;

    for (var p in people) {
      total += (p['amount'] ?? 0);
    }

    double equal = total / people.length;

    return people.map((p) {
      double paid = (p['amount'] ?? 0).toDouble();
      double balance = paid - equal;

      return {"name": p['name'], "balance": balance};
    }).toList();
  }

  /// 🔥 MINIMIZED SPLIT (SMART)
  List<Map<String, dynamic>> calculateSmartSplit(List people) {
    double total = 0;

    for (var p in people) {
      total += (p['amount'] ?? 0);
    }

    double equal = total / people.length;

    List<Map<String, dynamic>> creditors = [];
    List<Map<String, dynamic>> debtors = [];

    for (var p in people) {
      double paid = (p['amount'] ?? 0).toDouble();
      double balance = paid - equal;

      if (balance > 0) {
        creditors.add({"name": p['name'], "amount": balance});
      } else if (balance < 0) {
        debtors.add({"name": p['name'], "amount": -balance});
      }
    }

    List<Map<String, dynamic>> result = [];

    int i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      double debt = debtors[i]['amount'];
      double credit = creditors[j]['amount'];

      double settled = debt < credit ? debt : credit;

      result.add({
        "from": debtors[i]['name'],
        "to": creditors[j]['name'],
        "amount": settled.round(),
      });

      debtors[i]['amount'] -= settled;
      creditors[j]['amount'] -= settled;

      if (debtors[i]['amount'] == 0) i++;
      if (creditors[j]['amount'] == 0) j++;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final people = (data['people'] ?? []) as List;

    final balances = calculateBalances(people);
    final settlements = calculateSmartSplit(people);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 TITLE
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// 💰 TOTAL
                Text(
                  "Total: ₹${data['amount'] ?? 0}",
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 12),
                const Divider(),

                /// 👥 PARTICIPANTS (UNCHANGED)
                const Text(
                  "Participants",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                ...people.map((p) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(p['name'] ?? ''),
                    trailing: Text("₹${p['amount'] ?? 0}"),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(),

                /// 💰 BALANCES
                const Text(
                  "Balances",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                ...balances.map((b) {
                  final balance = b['balance'] as double;

                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(b['name']),
                    trailing: Text(
                      balance >= 0
                          ? "+₹${balance.round()}"
                          : "-₹${balance.abs().round()}",
                      style: TextStyle(
                        color: balance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Divider(),

                /// 🔥 SETTLEMENTS (SMART)
                const Text(
                  "Settlements",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                if (settlements.isEmpty) const Text("All settled 🎉"),

                ...settlements.map((s) {
                  return ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text("${s['from']} pays ${s['to']}"),
                    trailing: Text(
                      "₹${s['amount']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
