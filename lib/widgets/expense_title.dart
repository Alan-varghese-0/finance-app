import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/theme.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == TransactionType.income;

    return Dismissible(
      key: Key(expense.id), // make sure your model has id
      direction: DismissDirection.endToStart,

      /// 🔴 BACKGROUND (SWIPE UI)
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      /// ⚠️ CONFIRM BEFORE DELETE
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Transaction"),
            content: const Text(
              "Are you sure you want to delete this transaction?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },

      /// 🗑️ DELETE ACTION
      onDismissed: (direction) {
        onDelete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaction deleted"),
            duration: Duration(seconds: 2),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onEdit,

          /// 🔥 LEADING ICON
          leading: Icon(
            isIncome ? Icons.trending_down : Icons.trending_up,
            color: isIncome ? AppColors.income : AppColors.expense,
          ),

          /// TITLE
          title: Text(
            expense.title,
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          /// DATE
          subtitle: Text(
            expense.date.toString(), // later we can format
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          /// TRAILING
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${isIncome ? '+' : '-'}₹${expense.amount}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              // IconButton(
              //   onPressed: () async {
              //     final confirm = await showDialog(
              //       context: context,
              //       builder: (ctx) => AlertDialog(
              //         title: const Text("Delete Transaction"),
              //         content: const Text(
              //           "Are you sure you want to delete this transaction?",
              //         ),
              //         actions: [
              //           TextButton(
              //             onPressed: () => Navigator.of(ctx).pop(false),
              //             child: const Text("Cancel"),
              //           ),
              //           TextButton(
              //             onPressed: () => Navigator.of(ctx).pop(true),
              //             child: const Text(
              //               "Delete",
              //               style: TextStyle(color: Colors.red),
              //             ),
              //           ),
              //         ],
              //       ),
              //     );

              //     if (confirm == true) {
              //       onDelete();
              //     }
              //   },
              //   icon: const Icon(Icons.delete),
              //   color: AppColors.expense,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
