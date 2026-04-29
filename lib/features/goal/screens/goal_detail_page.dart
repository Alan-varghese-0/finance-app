import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class GoalDetailsPage extends StatelessWidget {
  final QueryDocumentSnapshot goalDoc;

  const GoalDetailsPage({super.key, required this.goalDoc});

  @override
  Widget build(BuildContext context) {
    final data = goalDoc.data() as Map<String, dynamic>;

    final goalRef = goalDoc.reference.collection('transactions');

    final saved = (data['savedAmount'] ?? 0).toDouble();
    final target = (data['targetAmount'] ?? 1).toDouble();
    final progress = (saved / target).clamp(0, 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(data['title'] ?? "Goal"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),

      /// ➕ ADD MONEY
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final controller = TextEditingController();

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Add Money"),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Enter amount"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(controller.text) ?? 0;
                    if (amount <= 0) return;

                    await goalRef.add({
                      "amount": amount,
                      "createdAt": Timestamp.now(),
                    });

                    await goalDoc.reference.update({
                      "savedAmount": FieldValue.increment(amount),
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: goalRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _bg(const CircularProgressIndicator());
          }

          final txns = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              /// 🔥 GOAL OVERVIEW CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Goal Progress",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "₹${saved.toInt()} / ₹${target.toInt()}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// 🔥 TRANSACTIONS HEADER
              const Text(
                "Transactions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              /// 🔥 EMPTY STATE
              if (txns.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text("No transactions yet")),
                ),

              /// 🔥 LIST
              ...txns.map((t) {
                final d = t.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.green),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "+₹${d['amount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d['createdAt'].toDate().toString().substring(
                                0,
                                16,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
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
