import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:finance_app/features/home/AllTransactionspage.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/features/subscribtion/widget/nearest_subscribtionpage.dart';
import 'package:finance_app/features/goal/widget/priorityGoal.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expence_chart.dart';
import '../widgets/expense_title.dart';

class ExpenseTab extends StatefulWidget {
  final CollectionReference expenseCollection;
  final CollectionReference subscriptionCollection;
  final CollectionReference goalsCollection;

  const ExpenseTab({
    super.key,
    required this.expenseCollection,
    required this.subscriptionCollection,
    required this.goalsCollection,
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

        /// ✅ NORMAL EXPENSES
        final expenses = expenseSnap.data!.docs
            .map((e) => Expense.fromMap(e.id, e.data() as Map<String, dynamic>))
            .toList();

        /// 🔥 SUBSCRIPTIONS STREAM
        return StreamBuilder<QuerySnapshot>(
          stream: widget.subscriptionCollection.snapshots(),
          builder: (context, subSnap) {
            if (!subSnap.hasData) {
              return _bg(const CircularProgressIndicator());
            }

            /// ✅ CONVERT SUBSCRIPTIONS → EXPENSE FORMAT
            final subscriptionExpenses = subSnap.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              final date = (data['nextDate'] as Timestamp).toDate();
              final amount = (data['amount'] ?? 0).toDouble();
              final repeat = data['repeatType'] ?? "monthly";

              double monthlyAmount = amount;

              if (repeat == "yearly") {
                monthlyAmount = amount / 12;
              } else if (repeat == "weekly") {
                monthlyAmount = amount * 4.33;
              } else if (repeat == "daily") {
                monthlyAmount = amount * 30.4;
              }

              return Expense(
                id: doc.id,
                title: data['title'],
                amount: monthlyAmount,
                date: date,
                type: TransactionType.expense,
                category: 'subscription',
              );
            }).toList();

            final allData = [...expenses, ...subscriptionExpenses];

            return Container(
              color: AppColors.background,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  /// 📊 CHART
                  SliverToBoxAdapter(child: ExpenseChart(expenses: allData)),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  /// 💳 SUBSCRIPTIONS
                  SliverToBoxAdapter(
                    child: NearestSubscriptionsWidget(
                      subscriptionCollection: widget.subscriptionCollection,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  /// 🎯 GOALS
                  SliverToBoxAdapter(
                    child: PriorityGoalsWidget(
                      goalsCollection: widget.goalsCollection,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  /// 📋 TRANSACTIONS CARD 🔥
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Transactions",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                "${expenses.length}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// LIST PREVIEW
                          if (expenses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No transactions yet",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                ...expenses.take(5).map((e) {
                                  return Column(
                                    children: [
                                      ExpenseTile(
                                        expense: e,
                                        onDelete: () => widget.expenseCollection
                                            .doc(e.id)
                                            .delete(),
                                        onEdit: () {},
                                      ),
                                      Divider(color: AppColors.border),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),

                          const SizedBox(height: 6),

                          /// VIEW ALL (future expansion)
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AllTransactionsPage(
                                        expenseCollection:
                                            widget.expenseCollection,
                                        subscriptionCollection:
                                            widget.subscriptionCollection,
                                        goalsCollection: widget.goalsCollection,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "View All Transactions",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            );
          },
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
