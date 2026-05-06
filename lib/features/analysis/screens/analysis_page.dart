import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:finance_app/features/split/split_self_person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:finance_app/features/analysis/widget/bar_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/line_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/pie_chart_widget.dart';
import 'package:finance_app/features/analysis/widget/smart_insight.dart';
import 'package:finance_app/features/analysis/widget/split_insight.dart';
import 'package:finance_app/features/analysis/widget/subscribtion_insight.dart';
import 'package:finance_app/features/analysis/widget/summery_card.dart';
import 'package:finance_app/theme/theme.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final fs = UserFirestore(uid);
    final expenseCollection = fs.expenses;
    final subscriptionCollection = fs.subscriptions;
    final splitCollection = fs.splits;

    return Container(
      color: AppColors.background,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 40)),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Analysis data",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),

          const SliverToBoxAdapter(child: SummaryCards()),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          _section(
            "Weekly Spending",
            BarChartWidget(expenseCollection: expenseCollection),
          ),
          _section(
            "Monthly Trend",
            LineChartWidget(expenseCollection: expenseCollection),
          ),

          _section(
            "Splits",
            SplitInsights(
              splitCollection: splitCollection,
              selfName: splitSelfDisplayName(FirebaseAuth.instance.currentUser),
            ),
          ),

          _section(
            "Subscriptions",
            SubscriptionInsights(
              subscriptionCollection: subscriptionCollection,
            ),
          ),

          _section(
            "Category Split",
            PieChartWidget(
              expenseCollection: expenseCollection,
              subscriptionCollection: subscriptionCollection,
              splitCollection: splitCollection,
            ),
          ),

          _section(
            "Smart Insights",
            StreamBuilder(
              stream: expenseCollection
                  .orderBy("date", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "No data available for insights",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final expenses = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Expense(
                    id: doc.id,
                    userId: data['userId'] ?? '',
                    title: data['title'] ?? '',
                    amount: (data['amount'] ?? 0).toDouble(),
                    date: (data['date'] as Timestamp).toDate(),

                    // ⚠️ IMPORTANT: never pass null
                    type: data['type'] == 'income'
                        ? TransactionType.income
                        : TransactionType.expense,

                    category: data['category'] ?? 'Other',
                    source: data['source'] ?? '',
                  );
                }).toList();

                return SmartInsights(expenses: expenses);
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
