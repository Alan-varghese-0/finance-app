import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SplitDetailsSheet extends StatelessWidget {
  final QueryDocumentSnapshot data;

  const SplitDetailsSheet({super.key, required this.data});

  /// 🔥 CHANGE THIS LATER (auth user)
  final String currentUser = "alan";

  /// 🔥 BALANCE
  List<Map<String, dynamic>> calculateBalances(List people) {
    return people.map((p) {
      double paid = (p['paid'] ?? 0).toDouble();
      double share = (p['share'] ?? 0).toDouble();

      double balance = paid - share;

      return {"name": p['name'], "balance": balance};
    }).toList();
  }

  /// 🔥 SMART SPLIT
  List<Map<String, dynamic>> calculateSmartSplit(List people) {
    List<Map<String, dynamic>> creditors = [];
    List<Map<String, dynamic>> debtors = [];

    for (var p in people) {
      double paid = (p['paid'] ?? 0).toDouble();
      double share = (p['share'] ?? 0).toDouble();

      double balance = paid - share;

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

  /// 🔥 YOU SUMMARY
  Map<String, dynamic> getUserSummary(List settlements) {
    double owe = 0;
    double get = 0;

    for (var s in settlements) {
      if (s['from'] == currentUser) {
        owe += s['amount'];
      } else if (s['to'] == currentUser) {
        get += s['amount'];
      }
    }

    return {"owe": owe, "get": get};
  }

  @override
  Widget build(BuildContext context) {
    final people = (data['people'] ?? []) as List;

    final balances = calculateBalances(people);
    final settlements = calculateSmartSplit(people);
    final summary = getUserSummary(settlements);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 TITLE
                Text(
                  data['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                /// 💰 TOTAL
                Text(
                  "Total: ₹${data['amount'] ?? 0}",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 16),

                /// 💥 YOU SUMMARY
                _youSummary(summary),

                const SizedBox(height: 16),

                /// 👥 PARTICIPANTS
                _sectionCard(
                  title: "Participants",
                  child: Column(
                    children: people.map((p) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person),
                        title: Text(p['name']),
                        subtitle: Text(
                          "Share: ₹${p['share']} | Paid: ₹${p['paid']}",
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                /// 💥 SETTLEMENTS
                _sectionCard(
                  title: "Who pays whom",
                  child: settlements.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("All settled 🎉"),
                        )
                      : Column(
                          children: settlements.map((s) {
                            bool isMe =
                                s['from'] == currentUser ||
                                s['to'] == currentUser;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary.withOpacity(0.08)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${s['from']} pays ${s['to']}",
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "₹${s['amount']}",
                                    style: const TextStyle(
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),

                const SizedBox(height: 40), // 👈 important spacing
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 CARD UI
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Widget _youSummary(Map<String, dynamic> summary) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You owe",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              "₹${summary['owe'].toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "You get",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              "₹${summary['get'].toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
