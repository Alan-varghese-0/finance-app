import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/categories.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:finance_app/features/expenses/screens/add_expense_screen.dart';
import 'package:finance_app/features/expenses/widgets/expence_chart.dart';
import 'package:finance_app/features/expenses/widgets/expense_title.dart';
import 'package:finance_app/features/goal/widget/priorityGoal.dart';
import 'package:finance_app/features/home/AllTransactionspage.dart';
import 'package:finance_app/features/subscribtion/widget/nearest_subscribtionpage.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (uid == null) {
      return const Center(child: Text("User not logged in"));
    }

    final selfName = FirebaseAuth.instance.currentUser?.displayName ?? "Me";

    return StreamBuilder<QuerySnapshot>(
      stream: widget.expenseCollection.snapshots(),
      builder: (context, expenseSnap) {
        if (!expenseSnap.hasData) {
          return _bg(const CircularProgressIndicator());
        }

        final expenses = expenseSnap.data!.docs
            .map((e) => Expense.fromMap(e.id, e.data() as Map<String, dynamic>))
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: widget.subscriptionCollection.snapshots(),
          builder: (context, subSnap) {
            if (!subSnap.hasData) {
              return _bg(const CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('splits')
                  .snapshots(),
              builder: (context, splitSnap) {
                if (!splitSnap.hasData) {
                  return _bg(const CircularProgressIndicator());
                }

                /// 🔥 SPLIT → TRANSACTIONS (FIXED DATE)
                List<Expense> splitExpenses = [];

                for (var doc in splitSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  final createdAt =
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now();

                  final owes = (data['owe'] ?? []) as List;

                  for (var o in owes) {
                    if (o['settled'] != true) continue;

                    final from = o['from'];
                    final to = o['to'];
                    final amount = (o['amount'] ?? 0).toDouble();

                    TransactionType? type;

                    if (from == selfName) {
                      type = TransactionType.expense;
                    } else if (to == selfName) {
                      type = TransactionType.income;
                    }

                    if (type == null) continue;

                    splitExpenses.add(
                      Expense(
                        id: "${doc.id}_${from}_${to}",
                        userId: uid!,
                        title: "Split Settlement",
                        amount: amount,
                        date: createdAt,
                        type: type,
                        category: canonicalCategoryName("split", type),
                        source: "split", // ✅ FIX
                      ),
                    );
                  }
                }

                /// 🔥 SUBSCRIPTIONS → EXPENSE
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
                    userId: uid!,
                    title: data['title'] ?? '',
                    amount: monthlyAmount,
                    date: date,
                    type: TransactionType.expense,
                    category: 'subscription',
                    source: "subscription", // ✅ FIX
                  );
                }).toList();

                /// 🔥 MERGE + SORT (MOST IMPORTANT)
                final allData = [
                  ...expenses,
                  ...subscriptionExpenses,
                  ...splitExpenses,
                ];

                // ✅ SORT BY LATEST
                allData.sort((a, b) => b.date.compareTo(a.date));

                return Container(
                  color: AppColors.background,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      /// 📊 CHART
                      SliverToBoxAdapter(
                        child: ExpenseChart(expenses: allData),
                      ),

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

                      /// 📋 RECENT TRANSACTIONS
                      allData.isEmpty
                          ? SliverToBoxAdapter(child: _emptyCard())
                          : SliverList(
                              delegate: SliverChildListDelegate([
                                _transactionCard(allData),
                              ]),
                            ),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔥 EMPTY
  Widget _emptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          "No transactions yet",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  /// 🔥 RECENT TRANSACTION CARD
  Widget _transactionCard(List<Expense> data) {
    return Container(
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
                "Recent Transactions",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllTransactionsPage(
                        expenseCollection: widget.expenseCollection,
                        subscriptionCollection: widget.subscriptionCollection,
                        goalsCollection: widget.goalsCollection,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔥 SHOW ONLY LATEST 5
          ...data.take(5).map((e) {
            return Column(
              children: [
                ExpenseTile(
                  expense: e,
                  onDelete: () async {
                    try {
                      if (e.source == "expense") {
                        await widget.expenseCollection.doc(e.id).delete();
                      } else if (e.source == "subscription") {
                        await widget.subscriptionCollection.doc(e.id).delete();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Cannot delete split here"),
                          ),
                        );
                      }
                    } catch (err) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Delete failed: $err")),
                      );
                    }
                  },
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(
                          id: e.id,
                          title: e.title,
                          amount: e.amount,
                          date: e.date,
                          type: e.type == TransactionType.income
                              ? "income"
                              : "expense",
                          category: e.category,
                        ),
                      ),
                    );
                  },
                ),
                Divider(color: AppColors.border),
              ],
            );
          }).toList(),
        ],
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
