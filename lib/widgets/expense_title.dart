import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/theme.dart';
import '../data/categories.dart';
import '../models/category.dart';

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

  /// 🔥 GET CATEGORY OBJECT
  CategoryModel getCategory(String name) {
    return categories.firstWhere(
      (c) => c.name == name,
      orElse: () => categories.first,
    );
  }

  /// 🔥 ICON MAPPER
  IconData getIcon(String name) {
    switch (name) {
      case "restaurant":
        return Icons.restaurant;
      case "directions_car":
        return Icons.directions_car;
      case "shopping_bag":
        return Icons.shopping_bag;
      case "receipt":
        return Icons.receipt;
      case "favorite":
        return Icons.favorite;
      case "movie":
        return Icons.movie;
      case "account_balance_wallet":
        return Icons.account_balance_wallet;
      case "laptop":
        return Icons.laptop;
      case "business_center":
        return Icons.business_center;
      case "trending_up":
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == TransactionType.income;

    /// 🔥 CATEGORY DATA
    final category = getCategory(expense.category);

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,

      /// 🔴 DELETE BACKGROUND
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

      /// ⚠️ CONFIRM DELETE
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

      /// 🗑 DELETE ACTION
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

          /// 🔥 CATEGORY ICON
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(category.color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIcon(category.icon), color: Color(category.color)),
          ),

          /// TITLE
          title: Text(
            expense.title,
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          /// 🔥 CATEGORY + DATE
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              /// CATEGORY CHIP
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(category.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(category.color),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              /// SMALL DATE (optional but recommended)
              Text(
                "${expense.date.day}/${expense.date.month}/${expense.date.year}",
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          /// 💰 AMOUNT
          trailing: Text(
            "${isIncome ? '+' : '-'}₹${expense.amount}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ),
      ),
    );
  }
}
