import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class SubscriptionTab extends StatefulWidget {
  final CollectionReference subscriptionCollection;

  const SubscriptionTab({super.key, required this.subscriptionCollection});

  @override
  State<SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<SubscriptionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: widget.subscriptionCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _bg(const CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return _bg(const Text("No subscriptions yet"));
        }

        /// 🔥 SORT BY NEAREST DATE
        final subs = snapshot.data!.docs.toList();
        subs.sort((a, b) {
          final aDate = (a['nextDate'] as Timestamp).toDate();
          final bDate = (b['nextDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        return Container(
          color: AppColors.background,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: subs.length,
            itemBuilder: (ctx, i) {
              final doc = subs[i];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              /// 🔥 DATE
              final date = (data['nextDate'] as Timestamp).toDate();
              final daysLeft = date.difference(DateTime.now()).inDays;

              /// 🔥 COMPLETION STATE
              final bool isCompleted = data['completed'] ?? false;
              final Timestamp? completedAt = data['completedAt'];

              /// 🔄 AUTO RESET AFTER 10 DAYS
              if (isCompleted && completedAt != null) {
                final completedDate = completedAt.toDate();
                final diff = DateTime.now().difference(completedDate).inDays;

                if (diff >= 10) {
                  widget.subscriptionCollection.doc(id).update({
                    'completed': false,
                    'completedAt': null,
                  });
                }
              }

              /// 🧠 DAY TEXT
              String dayText;
              if (isCompleted) {
                dayText = "Completed";
              } else if (daysLeft < 0) {
                dayText = "Overdue";
              } else if (daysLeft == 0) {
                dayText = "Today";
              } else if (daysLeft == 1) {
                dayText = "Tomorrow";
              } else {
                dayText = "in $daysLeft days";
              }

              /// 🎨 STATUS COLOR
              Color statusColor;
              if (isCompleted) {
                statusColor = Colors.grey;
              } else if (daysLeft <= 0) {
                statusColor = Colors.red;
              } else if (daysLeft <= 5) {
                statusColor = Colors.orange;
              } else {
                statusColor = Colors.green;
              }

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,

                /// 🔴 DELETE BG
                background: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                /// ❗ CONFIRM DELETE
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Subscription"),
                      content: const Text(
                        "Are you sure you want to delete this?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },

                /// 🗑 DELETE
                onDismissed: (direction) {
                  widget.subscriptionCollection.doc(id).delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Subscription deleted")),
                  );
                },

                /// 📦 CARD
                child: Opacity(
                  opacity: isCompleted ? 0.6 : 1,
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
                        /// ✅ CHECKBOX + ICON
                        Row(
                          children: [
                            Checkbox(
                              value: isCompleted,
                              onChanged: (val) {
                                widget.subscriptionCollection.doc(id).update({
                                  'completed': val,
                                  'completedAt': val! ? Timestamp.now() : null,
                                });
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.repeat, color: statusColor),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        /// 📄 TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$dayText • ${date.day}/${date.month}/${date.year}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// 💰 AMOUNT
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${data['amount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['repeatType'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 🎨 BACKGROUND
  Widget _bg(Widget child) {
    return Container(
      color: AppColors.background,
      child: Center(child: child),
    );
  }
}
