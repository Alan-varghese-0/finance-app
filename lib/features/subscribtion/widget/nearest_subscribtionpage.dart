import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/subscribtion/screens/subscribtion_tab.dart';
import 'package:finance_app/features/subscribtion/screens/add_subscribtion_screen.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class NearestSubscriptionsWidget extends StatelessWidget {
  final CollectionReference subscriptionCollection;

  const NearestSubscriptionsWidget({
    super.key,
    required this.subscriptionCollection,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: subscriptionCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _container(const CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        /// ✅ EMPTY STATE
        if (docs.isEmpty) {
          return _emptyState(context);
        }

        /// 🔥 SORT BY NEAREST DATE
        final subs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['completed'] != true; // ❌ remove completed ones
        }).toList();
        subs.sort((a, b) {
          final aDate = (a['nextDate'] as Timestamp).toDate();
          final bDate = (b['nextDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        /// 🔥 TAKE TOP 3
        final nearest = subs.take(3).toList();

        return Container(
          margin: const EdgeInsets.all(12),
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
                /// 🔹 HEADER (clickable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Upcoming Bills",
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
                            builder: (_) => SubscriptionTab(
                              subscriptionCollection: subscriptionCollection,
                            ),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// 🔥 LIST
                ...nearest.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['nextDate'] as Timestamp).toDate();

                  final daysLeft = date.difference(DateTime.now()).inDays;

                  /// 🧠 TEXT
                  String dayText;
                  if (daysLeft < 0) {
                    dayText = "Overdue";
                  } else if (daysLeft == 0) {
                    dayText = "Today";
                  } else if (daysLeft == 1) {
                    dayText = "Tomorrow";
                  } else {
                    dayText = "in $daysLeft days";
                  }

                  /// 🎨 COLOR
                  Color color;
                  if (daysLeft <= 0) {
                    color = Colors.red;
                  } else if (daysLeft <= 5) {
                    color = Colors.orange;
                  } else {
                    color = Colors.green;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, color: color),

                        const SizedBox(width: 10),

                        /// TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$dayText • ${date.day}/${date.month}",
                                style: TextStyle(fontSize: 12, color: color),
                              ),
                            ],
                          ),
                        ),

                        /// AMOUNT
                        Text(
                          "₹${data['amount']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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

  /// 🔥 EMPTY STATE (FIXED)
  Widget _emptyState(BuildContext context) {
    return GestureDetector(
      onTap: () => _goToSubscriptions(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat, size: 40, color: Colors.grey),

            const SizedBox(height: 10),

            const Text(
              "No subscriptions yet",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Tap to add your first subscription",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => _goToSubscriptions(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Add Subscription",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔁 NAVIGATION
  void _goToSubscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddSubscriptionScreen()),
    );
  }

  /// 🎨 LOADING / WRAPPER
  Widget _container(Widget child) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: child),
    );
  }
}
