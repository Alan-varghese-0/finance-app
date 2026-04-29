import 'package:finance_app/features/expenses/models/category.dart';
import 'package:flutter/material.dart';

final List<CategoryModel> categories = [
  /// 🔴 EXPENSE CATEGORIES
  CategoryModel(
    name: "Food",
    icon: "restaurant",
    color: Colors.orange.value,
    type: "expense",
  ),
  CategoryModel(
    name: "Travel",
    icon: "directions_car",
    color: Colors.blue.value,
    type: "expense",
  ),
  CategoryModel(
    name: "Shopping",
    icon: "shopping_bag",
    color: Colors.purple.value,
    type: "expense",
  ),
  CategoryModel(
    name: "Bills",
    icon: "receipt",
    color: Colors.red.value,
    type: "expense",
  ),
  CategoryModel(
    name: "Health",
    icon: "favorite",
    color: Colors.pink.value,
    type: "expense",
  ),
  CategoryModel(
    name: "Entertainment",
    icon: "movie",
    color: Colors.indigo.value,
    type: "expense",
  ),

  /// 🟢 INCOME CATEGORIES
  CategoryModel(
    name: "Salary",
    icon: "account_balance_wallet",
    color: Colors.green.value,
    type: "income",
  ),
  CategoryModel(
    name: "Freelance",
    icon: "laptop",
    color: Colors.teal.value,
    type: "income",
  ),
  CategoryModel(
    name: "Business",
    icon: "business_center",
    color: Colors.lightGreen.value,
    type: "income",
  ),
  CategoryModel(
    name: "Investment",
    icon: "trending_up",
    color: Colors.amber.value,
    type: "income",
  ),
];
