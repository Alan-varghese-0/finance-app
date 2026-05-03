import 'package:flutter/material.dart';
import 'package:finance_app/features/expenses/models/category.dart';

final List<CategoryModel> categories = [
  /// 🔴 EXPENSE (vivid + readable)
  CategoryModel(
    name: "Food",
    icon: Icons.restaurant,
    color: const Color(0xFFEAB308), // Golden yellow - warm food
    type: "expense",
  ),
  CategoryModel(
    name: "Travel",
    icon: Icons.directions_car,
    color: const Color(0xFF3B82F6), // Blue - reliable, transport
    type: "expense",
  ),
  CategoryModel(
    name: "Shopping",
    icon: Icons.shopping_bag,
    color: const Color(0xFFEC4899), // Pink - retail therapy
    type: "expense",
  ),
  CategoryModel(
    name: "Bills",
    icon: Icons.receipt,
    color: const Color(0xFFEF4444), // Red - attention required
    type: "expense",
  ),
  CategoryModel(
    name: "Health",
    icon: Icons.favorite,
    color: const Color(
      0xFF10B981,
    ), // Emerald - health/life (lighter than income)
    type: "expense",
  ),
  CategoryModel(
    name: "Entertainment",
    icon: Icons.movie,
    color: const Color(0xFF8B5CF6), // Vivid purple - fun
    type: "expense",
  ),

  /// 🟢 INCOME (bright green system)
  CategoryModel(
    name: "Salary",
    icon: Icons.account_balance_wallet,
    color: const Color(0xFF4ADE80), // green
    type: "income",
  ),
  CategoryModel(
    name: "Freelance",
    icon: Icons.laptop,
    color: const Color(0xFF2DD4BF), // teal
    type: "income",
  ),
  CategoryModel(
    name: "Business",
    icon: Icons.business_center,
    color: const Color(0xFF22C55E), // deeper green
    type: "income",
  ),
  CategoryModel(
    name: "Investment",
    icon: Icons.trending_up,
    color: const Color(0xFFA3E635), // lime
    type: "income",
  ),
];
