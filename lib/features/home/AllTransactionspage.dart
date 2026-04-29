import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class AllTransactionsPage extends StatelessWidget {
  final CollectionReference expenseCollection;
  final CollectionReference subscriptionCollection;
  final CollectionReference goalsCollection;

  const AllTransactionsPage({
    super.key,
    required this.expenseCollection,
    required this.subscriptionCollection,
    required this.goalsCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("All Transactions"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expenseCollection.snapshots(),
        builder: (context, expenseSnap) {
          if (!expenseSnap.hasData) {
            return _bg(const CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: subscriptionCollection.snapshots(),
            builder: (context, subSnap) {
              if (!subSnap.hasData) {
                return _bg(const CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot>(
                stream: goalsCollection.snapshots(),
                builder: (context, goalSnap) {
                  if (!goalSnap.hasData) {
                    return _bg(const CircularProgressIndicator());
                  }

                  List<Map<String, dynamic>> all = [];

                  /// 🔥 EXPENSES
                  for (var doc in expenseSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;

                    final type = d['type'] ?? 'expense'; // ✅ dynamic

                    all.add({
                      "title": d['title'],
                      "amount": d['amount'],
                      "date": (d['date'] as Timestamp).toDate(),
                      "type": type, // ✅ FIXED
                    });
                  }

                  /// 🔥 SUBSCRIPTIONS
                  for (var doc in subSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    all.add({
                      "title": d['title'],
                      "amount": d['amount'],
                      "date": (d['nextDate'] as Timestamp).toDate(),
                      "type": "subscription",
                    });
                  }

                  /// 🔥 GOAL TRANSACTIONS
                  for (var goal in goalSnap.data!.docs) {
                    final goalData = goal.data() as Map<String, dynamic>;

                    final txns = (goalData['transactions'] ?? []) as List;

                    for (var t in txns) {
                      all.add({
                        "title": goalData['title'],
                        "amount": t['amount'],
                        "date": (t['createdAt'] as Timestamp).toDate(),
                        "type": "goal",
                      });
                    }
                  }

                  /// 🔥 SORT (LATEST FIRST)
                  all.sort((a, b) => b['date'].compareTo(a['date']));

                  if (all.isEmpty) {
                    return _bg(
                      const Text(
                        "No transactions found",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: all.length,
                    itemBuilder: (context, i) {
                      final item = all[i];

                      Color color;
                      IconData icon;

                      switch (item['type']) {
                        case "income":
                          color = AppColors.income;
                          icon = Icons.arrow_downward;
                          break;

                        case "expense":
                          color = AppColors.expense;
                          icon = Icons.arrow_upward;
                          break;

                        case "subscription":
                          color = Colors.orange;
                          icon = Icons.repeat;
                          break;

                        case "goal":
                          color = Colors.green;
                          icon = Icons.flag;
                          break;

                        default:
                          color = Colors.grey;
                          icon = Icons.circle;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color),
                            ),

                            const SizedBox(width: 12),

                            /// TEXT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['type'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// RIGHT
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${item['amount']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['date'].toString().substring(0, 10),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _bg(Widget child) {
    return Container(
      color: AppColors.background,
      child: Center(child: child),
    );
  }
}
