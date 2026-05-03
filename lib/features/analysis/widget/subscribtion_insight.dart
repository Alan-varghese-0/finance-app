import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class SubscriptionInsights extends StatelessWidget {
  final CollectionReference subscriptionCollection;

  const SubscriptionInsights({super.key, required this.subscriptionCollection});

  Stream<Map<String, dynamic>> getSubscriptionData() {
    return subscriptionCollection.snapshots().map((snapshot) {
      double total = 0;
      String nextName = "None";
      DateTime? nextDate;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final amount = (data['amount'] ?? 0).toDouble();
        total += amount;

        final name = data['title'] ?? "Subscription";

        final date = data['nextDate'];
        if (date != null && date is Timestamp) {
          final d = date.toDate();

          if (nextDate == null || d.isBefore(nextDate!)) {
            nextDate = d;
            nextName = name;
          }
        }
      }

      return {"total": total, "next": nextName, "date": nextDate};
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: getSubscriptionData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final total = data["total"] ?? 0;
        final next = data["next"] ?? "None";
        final date = data["date"] as DateTime?;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              /// ICON
              const Icon(Icons.subscriptions, color: AppColors.subscription),

              const SizedBox(width: 12),

              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total: ₹${total.toStringAsFixed(0)}/month",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Next: $next",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (date != null)
                      Text(
                        "Due: ${date.toString().substring(0, 10)}",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
