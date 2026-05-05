import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/categories.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class SplitDetailsSheet extends StatefulWidget {
  final QueryDocumentSnapshot data;
  final String selfName;

  const SplitDetailsSheet({
    super.key,
    required this.data,
    required this.selfName,
  });

  @override
  State<SplitDetailsSheet> createState() => _SplitDetailsSheetState();
}

class _SplitDetailsSheetState extends State<SplitDetailsSheet> {
  late List<Map<String, dynamic>> settlements;

  @override
  void initState() {
    super.initState();

    settlements = List<Map<String, dynamic>>.from((widget.data['owe'] ?? []));
  }

  String _label(String? name) {
    if (name == null || name.isEmpty) return '';
    return name == widget.selfName ? 'You' : name;
  }

  /// 🔥 MARK COMPLETE
  Future<void> markComplete(int index) async {
    final s = settlements[index];

    if (s['isSettled'] == true) return;

    final from = s['from'];
    final to = s['to'];
    final amount = (s['amount'] ?? 0).toDouble();

    /// 🔥 DETERMINE TYPE
    String type = "";
    if (from == widget.selfName) {
      type = "expense";
    } else if (to == widget.selfName) {
      type = "income";
    }

    /// 🔥 ADD TO EXPENSE COLLECTION
    final userId = widget.data['userId'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .add({
          "title": "Split Settlement",
          "amount": amount,
          "type": type,
          "category": canonicalCategoryName(
            "split",
            type == "income"
                ? TransactionType.income
                : TransactionType.expense,
          ),
          "date": Timestamp.now(),
        });

    /// 🔥 UPDATE FIRESTORE
    settlements[index]['isSettled'] = true;

    await widget.data.reference.update({"owe": settlements});

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.data['title'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Total: ₹${widget.data['amount'] ?? 0}",
                style: const TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 16),

              /// 🔥 SETTLEMENTS WITH CHECKBOX
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: settlements.asMap().entries.map((entry) {
                    int i = entry.key;
                    var s = entry.value;

                    bool done = s['isSettled'] == true;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: done
                            ? Colors.green.withOpacity(0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: done,
                            onChanged: (_) => markComplete(i),
                          ),
                          Expanded(
                            child: Text(
                              "${_label(s['from'])} pays ${_label(s['to'])}",
                              style: TextStyle(
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            "₹${s['amount']}",
                            style: TextStyle(
                              color: done ? Colors.green : AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
