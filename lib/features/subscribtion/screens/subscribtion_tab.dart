import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/features/subscribtion/screens/add_subscribtion_screen.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscriptions"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.subscriptionCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _bg(const CircularProgressIndicator());
          }

          final subs = snapshot.data!.docs.toList();

          /// 🔥 SORT BY DATE
          subs.sort((a, b) {
            final aDate = (a['nextDate'] as Timestamp).toDate();
            final bDate = (b['nextDate'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });

          return Container(
            color: AppColors.background,
            child: Column(
              children: [
                /// 🔥 OVERVIEW
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _subscriptionOverview(subs),
                ),

                /// ➕ ADD BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddSubscriptionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        "Add Subscription",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// 📜 LIST
                Expanded(
                  child: subs.isEmpty
                      ? Center(
                          child: Text(
                            "No subscriptions yet",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: subs.length,
                          itemBuilder: (ctx, i) {
                            final doc = subs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id;

                            final date = (data['nextDate'] as Timestamp)
                                .toDate();
                            final daysLeft = date
                                .difference(DateTime.now())
                                .inDays;

                            final bool isCompleted = data['completed'] ?? false;
                            final Timestamp? completedAt = data['completedAt'];

                            /// 🔁 AUTO RESET AFTER 10 DAYS
                            if (isCompleted && completedAt != null) {
                              final diff = DateTime.now()
                                  .difference(completedAt.toDate())
                                  .inDays;

                              if (diff >= 10) {
                                widget.subscriptionCollection.doc(id).update({
                                  'completed': false,
                                  'completedAt': null,
                                });
                              }
                            }

                            /// 🧠 TEXT
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

                            /// 🎨 COLOR
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

                            return _subscriptionItem(
                              doc: doc,
                              data: data,
                              id: id,
                              isCompleted: isCompleted,
                              dayText: dayText,
                              statusColor: statusColor,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔥 OVERVIEW CARD
  Widget _subscriptionOverview(List<QueryDocumentSnapshot> subs) {
    double total = 0;

    for (var s in subs) {
      final data = s.data() as Map<String, dynamic>;

      /// ❌ ignore completed
      if (data['completed'] != true) {
        total += (data['amount'] ?? 0);
      }
    }

    return Container(
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
            "Active Subscriptions",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            "₹${total.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 ITEM UI
  Widget _subscriptionItem({
    required QueryDocumentSnapshot doc,
    required Map<String, dynamic> data,
    required String id,
    required bool isCompleted,
    required String dayText,
    required Color statusColor,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        widget.subscriptionCollection.doc(id).delete();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.repeat, color: statusColor),
            ),

            const SizedBox(width: 12),

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
                  const SizedBox(height: 4),
                  Text(
                    "$dayText • ${data['nextDate'].toDate().day}/${data['nextDate'].toDate().month}",
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ],
              ),
            ),

            /// RIGHT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${data['amount']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
    );
  }

  Widget _bg(Widget child) {
    return Container(
      color: AppColors.background,
      child: Center(child: child),
    );
  }
}
