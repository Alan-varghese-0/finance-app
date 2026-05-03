import 'package:finance_app/data/firestore_user.dart';
import 'package:finance_app/features/expenses/screens/add_expense_screen.dart';
import 'package:finance_app/features/expenses/screens/expenses_tab.dart';
import 'package:finance_app/features/split/screens/add_split_screen.dart';
import 'package:finance_app/features/split/screens/split_tab.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 🔥 KEEP ALIVE WRAPPER (prevents tab rebuild)
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    /// 🔥 NO setState listener here
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fs = UserFirestore(uid);
    final expenseCollection = fs.expenses;
    final subscriptionCollection = fs.subscriptions;
    final splitCollection = fs.splits;
    final goalsCollection = fs.goals;

    return Scaffold(
      backgroundColor: AppColors.background,

      /// 🔥 APP BAR
      appBar: AppBar(
        title: const Text(
          "Expense Tracker",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,

        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Expenses"),
            Tab(text: "Splits"),
          ],
        ),
      ),

      /// 🔥 BODY (NO REBUILD NOW)
      body: TabBarView(
        controller: _tabController,
        children: [
          PrimaryScrollController(
            controller: ScrollController(),
            child: KeepAliveWrapper(
              child: ExpenseTab(
                expenseCollection: expenseCollection,
                subscriptionCollection: subscriptionCollection,
                goalsCollection: goalsCollection,
              ),
            ),
          ),
          PrimaryScrollController(
            controller: ScrollController(),
            child: KeepAliveWrapper(
              child: SplitTab(splitCollection: splitCollection),
            ),
          ),
        ],
      ),

      /// 🔥 FAB (SMART + SMOOTH)
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isExpenseTab = _tabController.index == 0;

          return FloatingActionButton(
            backgroundColor: isExpenseTab
                ? AppColors.income
                : AppColors.primary,

            onPressed: () {
              if (isExpenseTab) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSplitScreen()),
                );
              }
            },

            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isExpenseTab ? Icons.add : Icons.group,
                key: ValueKey(isExpenseTab),
              ),
            ),
          );
        },
      ),
    );
  }
}
