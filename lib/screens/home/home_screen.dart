import 'package:finance_app/screens/home/expenses_tab.dart';
import 'package:finance_app/screens/home/split_tab.dart';
import 'package:finance_app/screens/insert%20pages/add_expense_screen.dart';
import 'package:finance_app/screens/insert%20pages/add_split_screen.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final expenseCollection = FirebaseFirestore.instance.collection('expenses');
  final subscriptionCollection = FirebaseFirestore.instance.collection(
    'subscriptions',
  );

  final splitCollection = FirebaseFirestore.instance.collection(
    'splits',
  ); // ✅ NEW

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Expense Tracker",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          tabs: const [
            Tab(text: "Expenses"),
            Tab(text: "Splits"), // ✅ Correct now
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseTab(
            expenseCollection: expenseCollection,
            subscriptionCollection: subscriptionCollection,
          ),

          /// ✅ SPLIT TAB (FIXED)
          SplitTab(splitCollection: splitCollection),
        ],
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          } else {
            /// ✅ ADD SPLIT
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddSplitScreen()),
            );
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _tabController.index == 0
                ? Icons.add
                : Icons.group, // ✅ better icon
            key: ValueKey(_tabController.index),
          ),
        ),
      ),
    );
  }
}
