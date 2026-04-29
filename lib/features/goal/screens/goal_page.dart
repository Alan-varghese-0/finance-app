import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/goal/screens/goal_detail_page.dart';
import 'package:finance_app/features/goal/screens/add_goal_page.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class GoalsPage extends StatelessWidget {
  final CollectionReference goalsCollection;

  const GoalsPage({super.key, required this.goalsCollection});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),

      /// ➕ ADD GOAL
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.textPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGoalPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: goalsCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _bg(const CircularProgressIndicator());
          }

          final goals = snapshot.data!.docs;

          /// 🔥 EMPTY STATE (IMPROVED)
          if (goals.isEmpty) {
            return _bg(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No goals yet",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Tap + to create your first goal",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          /// 🔥 GOALS LIST
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final doc = goals[i];
              final data = doc.data() as Map<String, dynamic>;

              final saved = (data['savedAmount'] ?? 0).toDouble();
              final target = (data['targetAmount'] ?? 1).toDouble();
              final progress = target == 0 ? 0 : (saved / target).clamp(0, 1);

              final priority = data['priority'] ?? 0;

              /// 🎨 SAME PRIORITY COLOR SYSTEM
              Color priorityColor(int p) {
                if (p >= 5) return const Color(0xFFE53935);
                if (p == 4) return const Color(0xFFFF7043);
                if (p == 3) return const Color(0xFFFFCA28);
                if (p == 2) return const Color(0xFF42A5F5);
                return const Color(0xFF66BB6A);
              }

              final color = priorityColor(priority);

              /// 📅 DEADLINE
              final deadline = data['deadline'] != null
                  ? (data['deadline'] as Timestamp).toDate()
                  : null;

              String deadlineText = "";
              if (deadline != null) {
                final days = deadline.difference(DateTime.now()).inDays;
                if (days < 0) {
                  deadlineText = "Overdue";
                } else if (days == 0) {
                  deadlineText = "Today";
                } else {
                  deadlineText = "$days days left";
                }
              }

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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      /// 🔹 LEFT ICON BLOCK
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.flag, color: color),
                      ),

                      const SizedBox(width: 12),

                      /// 🔹 MAIN CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITLE
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// PROGRESS BAR
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: color.withOpacity(0.2),
                              color: color,
                            ),

                            const SizedBox(height: 6),

                            /// AMOUNT + DEADLINE
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "₹${saved.toInt()} / ₹${target.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (deadlineText.isNotEmpty)
                                  Text(
                                    deadlineText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      /// 🔹 PRIORITY BADGE
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
