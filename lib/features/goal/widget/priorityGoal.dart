import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/goal/screens/goal_detail_page.dart';
import 'package:finance_app/features/goal/screens/goal_page.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class PriorityGoalsWidget extends StatelessWidget {
  final CollectionReference goalsCollection;

  const PriorityGoalsWidget({super.key, required this.goalsCollection});

  /// 🎨 PRIORITY COLOR
  Color priorityColor(int p) {
    if (p >= 5) return const Color(0xFFE53935); // red
    if (p == 4) return const Color(0xFFFF7043); // orange
    if (p == 3) return const Color(0xFFFFCA28); // amber
    if (p == 2) return const Color(0xFF42A5F5); // blue
    return const Color(0xFF66BB6A); // green
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: goalsCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final goals = snapshot.data!.docs.toList();

        /// 🔥 SORT BY PRIORITY (HIGH → LOW)
        goals.sort((a, b) {
          final pa = (a.data() as Map<String, dynamic>)['priority'] ?? 0;
          final pb = (b.data() as Map<String, dynamic>)['priority'] ?? 0;
          return pb.compareTo(pa);
        });

        /// 🔥 TAKE TOP 4
        final topGoals = goals.take(4).toList();

        /// ================= EMPTY STATE =================
        if (topGoals.isEmpty) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalsPage(goalsCollection: goalsCollection),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.flag, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No goals assigned",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Tap to create your first goal",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GoalsPage(goalsCollection: goalsCollection),
                        ),
                      );
                    },
                    child: const Text("Add Goal"),
                  ),
                ],
              ),
            ),
          );
        }

        /// ================= NORMAL STATE =================
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Priority Goals",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GoalsPage(goalsCollection: goalsCollection),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// 🔥 GOAL LIST
                ...topGoals.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final saved = (data['savedAmount'] ?? 0).toDouble();
                  final target = (data['targetAmount'] ?? 1).toDouble();
                  final progress = target == 0
                      ? 0
                      : (saved / target).clamp(0, 1);

                  final priority = data['priority'] ?? 0;
                  final color = priorityColor(priority);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GoalDetailsPage(goalDoc: doc),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: color),

                          const SizedBox(width: 10),

                          /// TEXT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                /// PROGRESS BAR
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: color.withOpacity(0.2),
                                  color: color,
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "₹${saved.toInt()} / ₹${target.toInt()}",
                                  style: TextStyle(fontSize: 12, color: color),
                                ),
                              ],
                            ),
                          ),

                          /// PRIORITY BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "P$priority",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
