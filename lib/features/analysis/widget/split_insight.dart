import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SplitInsights extends StatelessWidget {
  final CollectionReference splitCollection;
  /// Must match the `name` stored for the signed-in user in split / people (see [splitSelfDisplayName]).
  final String selfName;

  const SplitInsights({
    super.key,
    required this.splitCollection,
    required this.selfName,
  });

  Stream<List<_SplitChart>> getSplitData() {
    return splitCollection.snapshots().map((snapshot) {
      double youOwe = 0;
      double owedToYou = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final owes = (data['owe'] ?? []) as List;

        for (var o in owes) {
          final map = Map<String, dynamic>.from(o);

          final amount = (map['amount'] ?? 0).toDouble();

          final from = map['from'];
          final to = map['to'];

          /// `from` owes `to` this amount.
          if (from == selfName) {
            youOwe += amount;
          }
          if (to == selfName) {
            owedToYou += amount;
          }
        }
      }

      return [
        _SplitChart("You owe", youOwe, Colors.redAccent),
        _SplitChart("Owed to you", owedToYou, Colors.greenAccent),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_SplitChart>>(
      stream: getSplitData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!;

        return SizedBox(
          height: 220,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: [
              ColumnSeries<_SplitChart, String>(
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.value,
                pointColorMapper: (d, _) => d.color,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SplitChart {
  final String label;
  final double value;
  final Color color;

  _SplitChart(this.label, this.value, this.color);
}
