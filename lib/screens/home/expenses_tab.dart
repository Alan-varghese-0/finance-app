import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/models/expense.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/widgets/expence_chart.dart';
import 'package:finance_app/widgets/expense_title.dart';
import 'package:flutter/material.dart';

class ExpenseTab extends StatefulWidget {
  final CollectionReference expenseCollection;
  final CollectionReference subscriptionCollection;

  const ExpenseTab({
    super.key,
    required this.expenseCollection,
    required this.subscriptionCollection,
  });

  @override
  State<ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<ExpenseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: widget.expenseCollection.snapshots(),
      builder: (context, expenseSnap) {
        if (!expenseSnap.hasData) {
          return _bg(const CircularProgressIndicator());
        }

        final expenses = expenseSnap.data!.docs
            .map((e) => Expense.fromMap(e.id, e.data() as Map<String, dynamic>))
            .toList();

        /// 🔥 SECOND STREAM (SUBSCRIPTIONS)
        return StreamBuilder<QuerySnapshot>(
          stream: widget.subscriptionCollection.snapshots(),
          builder: (context, subSnap) {
            if (!subSnap.hasData) {
              return _bg(const CircularProgressIndicator());
            }

            final subscriptions = subSnap.data!.docs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList();

            return Container(
              color: AppColors.background,
              child: Column(
                children: [
                  /// 🔥 UPDATED CHART
                  ExpenseChart(expenses: expenses),

                  /// LIST
                  Expanded(
                    child: ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (ctx, i) {
                        final e = expenses[i];

                        return ExpenseTile(
                          expense: e,
                          onDelete: () =>
                              widget.expenseCollection.doc(e.id).delete(),
                          onEdit: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bg(Widget child) {
    return Container(
      color: AppColors.background,
      child: Center(child: child),
    );
  }
}
