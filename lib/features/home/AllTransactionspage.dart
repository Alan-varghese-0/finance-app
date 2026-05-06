import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/features/expenses/screens/add_expense_screen.dart';

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

  /// 🔥 DELETE CONFIRM POPUP
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Transaction"),
            content: const Text(
              "Are you sure you want to delete this transaction?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

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

              List<Map<String, dynamic>> all = [];

              /// 🔥 EXPENSES
              for (var doc in expenseSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;

                all.add({
                  "id": doc.id,
                  "title": d['title'],
                  "amount": d['amount'],
                  "date": (d['date'] as Timestamp).toDate(),
                  "type": d['type'] ?? 'expense',
                  "source": "expense",
                  "category": d['category'],
                });
              }

              /// 🔥 SUBSCRIPTIONS
              for (var doc in subSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;

                all.add({
                  "id": doc.id,
                  "title": d['title'],
                  "amount": d['amount'],
                  "date": (d['nextDate'] as Timestamp).toDate(),
                  "type": "expense",
                  "source": "subscription",
                  "category": "subscription",
                });
              }

              /// 🔥 SORT
              all.sort((a, b) => b['date'].compareTo(a['date']));

              if (all.isEmpty) {
                return _bg(const Text("No transactions found"));
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
                    default:
                      color = Colors.grey;
                      icon = Icons.circle;
                  }

                  return Dismissible(
                    key: Key(item['id']),
                    direction: DismissDirection.endToStart,

                    /// 🔴 DELETE BG
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    /// 🔥 CONFIRM BEFORE DELETE
                    confirmDismiss: (_) async {
                      return await _confirmDelete(context);
                    },

                    /// 🔥 DELETE ACTION
                    onDismissed: (_) async {
                      try {
                        if (item['source'] == "expense") {
                          await expenseCollection.doc(item['id']).delete();
                        } else if (item['source'] == "subscription") {
                          await subscriptionCollection.doc(item['id']).delete();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Deleted successfully")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Delete failed: $e")),
                        );
                      }
                    },

                    /// 🔥 EDIT ON TAP
                    child: GestureDetector(
                      onTap: () {
                        if (item['source'] == "expense") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(
                                id: item['id'],
                                title: item['title'],
                                amount: item['amount'],
                                date: item['date'],
                                type: item['type'],
                                category: item['category'],
                              ),
                            ),
                          );
                        }
                      },

                      child: Container(
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
                                Text(
                                  item['date'].toString().substring(0, 10),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
