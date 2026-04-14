// ignore_for_file: unused_local_variable

import 'package:finance_app/widgets/expence_chart.dart';
import 'package:finance_app/widgets/expense_title.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatelessWidget {
  final collection = FirebaseFirestore.instance.collection('expenses');

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Tracker")),

      body: StreamBuilder<QuerySnapshot>(
        stream: collection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No expenses yet"));
          }

          final expenses = snapshot.data!.docs
              .map(
                (e) => Expense.fromMap(e.id, e.data() as Map<String, dynamic>),
              )
              .toList();

          double income = 0, expense = 0;

          for (var e in expenses) {
            if (e.type == TransactionType.income) {
              income += e.amount;
            } else {
              expense += e.amount;
            }
          }

          final balance = income - expense;

          return Column(
            children: [
              /// CHART
              ExpenseChart(expenses: expenses),

              /// LIST
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = expenses[i];

                    return ExpenseTile(
                      expense: e,
                      onDelete: () => collection.doc(e.id).delete(),
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                              id: e.id,
                              title: e.title,
                              amount: e.amount,
                              date: e.date,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
