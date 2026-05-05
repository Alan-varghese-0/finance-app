import 'package:flutter/material.dart';
import 'package:finance_app/features/expenses/models/category.dart';
import 'package:finance_app/features/expenses/models/expense.dart';

/// Maps legacy `"split"` / snake_case ids to names in [categories].
String canonicalCategoryName(String stored, TransactionType type) {
  final r = stored.toLowerCase().trim();
  if (r == 'split') {
    return type == TransactionType.expense ? 'Split (out)' : 'Split (in)';
  }
  if (r == 'split_expense') return 'Split (out)';
  if (r == 'split_income') return 'Split (in)';
  return stored;
}

final List<CategoryModel> categories = [
  /// 🔴 EXPENSE
  CategoryModel(
    name: "Food",
    icon: Icons.restaurant,
    color: const Color(0xFFEAB308),
    type: "expense",
  ),
  CategoryModel(
    name: "Travel",
    icon: Icons.directions_car,
    color: const Color(0xFF3B82F6),
    type: "expense",
  ),
  CategoryModel(
    name: "Shopping",
    icon: Icons.shopping_bag,
    color: const Color(0xFFEC4899),
    type: "expense",
  ),
  CategoryModel(
    name: "Bills",
    icon: Icons.receipt,
    color: const Color(0xFFEF4444),
    type: "expense",
  ),
  CategoryModel(
    name: "Health",
    icon: Icons.favorite,
    color: const Color(0xFF10B981),
    type: "expense",
  ),
  CategoryModel(
    name: "Entertainment",
    icon: Icons.movie,
    color: const Color(0xFF8B5CF6),
    type: "expense",
  ),

  /// Split settlement — you paid (not shown in manual category picker)
  CategoryModel(
    name: "Split (out)",
    icon: Icons.call_made,
    color: const Color(0xFFF97316),
    type: "expense",
    pickable: false,
  ),

  /// 🟢 INCOME
  CategoryModel(
    name: "Salary",
    icon: Icons.account_balance_wallet,
    color: const Color(0xFF4ADE80),
    type: "income",
  ),
  CategoryModel(
    name: "Freelance",
    icon: Icons.laptop,
    color: const Color(0xFF2DD4BF),
    type: "income",
  ),
  CategoryModel(
    name: "Business",
    icon: Icons.business_center,
    color: const Color(0xFF22C55E),
    type: "income",
  ),
  CategoryModel(
    name: "Investment",
    icon: Icons.trending_up,
    color: const Color(0xFFA3E635),
    type: "income",
  ),

  /// Split settlement — you received (not shown in manual category picker)
  CategoryModel(
    name: "Split (in)",
    icon: Icons.call_received,
    color: const Color(0xFF22C55E),
    type: "income",
    pickable: false,
  ),
];
