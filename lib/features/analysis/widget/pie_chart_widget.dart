import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChartWidget extends StatelessWidget {
  final CollectionReference expenseCollection;
  final CollectionReference subscriptionCollection;
  final CollectionReference splitCollection;

  const PieChartWidget({
    super.key,
    required this.expenseCollection,
    required this.subscriptionCollection,
    required this.splitCollection,
  });

  Stream<List<_ChartData>> getData() {
    return expenseCollection.snapshots().asyncMap((expenseSnap) async {
      final subs = await subscriptionCollection.get();
      final splits = await splitCollection.get();

      double income = 0;
      double expense = 0;
      double subscription = 0;
      double split = 0;

      /// 🔥 EXPENSE + INCOME
      for (var d in expenseSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['type'];

        if (type == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      /// 🔥 SUBSCRIPTIONS
      for (var d in subs.docs) {
        final data = d.data() as Map<String, dynamic>;
        subscription += (data['amount'] ?? 0).toDouble();
      }

      /// 🔥 SPLITS
      for (var d in splits.docs) {
        final data = d.data() as Map<String, dynamic>;
        split += (data['amount'] ?? 0).toDouble();
      }

      final list = [
        _ChartData("Income", income, const Color(0xFF4ADE80)),
        _ChartData("Expense", expense, const Color(0xFFEF4444)),
        _ChartData("Subscription", subscription, const Color(0xFF38BDF8)),
        _ChartData("Split", split, const Color(0xFFA78BFA)),
      ];

      /// remove zero values (IMPORTANT)
      return list.where((e) => e.amount > 0).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_ChartData>>(
      stream: getData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;
        final total = data.fold(0.0, (a, b) => a + b.amount);

        return Column(
          children: [
            /// 🥧 CHART
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: const Legend(isVisible: false),
                series: [
                  DoughnutSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.name,
                    yValueMapper: (d, _) => d.amount,
                    pointColorMapper: (d, _) => d.color,
                    innerRadius: '65%',

                    dataLabelMapper: (d, _) {
                      if (total == 0) return '';
                      final percent = (d.amount / total) * 100;
                      return '${percent.toStringAsFixed(0)}%';
                    },

                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// 🔥 CLEAN FIXED LEGEND (NO SCROLL, NO LIST ISSUES)
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 6,
              ),
              children: data.map((e) {
                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${e.name} ₹${e.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ChartData {
  final String name;
  final double amount;
  final Color color;

  _ChartData(this.name, this.amount, this.color);
}
