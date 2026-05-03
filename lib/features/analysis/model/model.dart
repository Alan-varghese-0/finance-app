class ExpenseCategory {
  final String name;
  final double amount;

  ExpenseCategory(this.name, this.amount);
}

class MockData {
  static List<ExpenseCategory> categories = [
    ExpenseCategory("Food", 3000),
    ExpenseCategory("Travel", 1500),
    ExpenseCategory("Shopping", 2000),
    ExpenseCategory("Subscriptions", 1200),
  ];

  static List<double> weeklySpending = [500, 700, 300, 900, 1200, 800, 600];

  static List<double> monthlySpending = [2000, 3000, 2500, 4000, 3500, 4200];
}

/// 🔥 Separate models (IMPORTANT FIX)
class CategoryChartData {
  final String x;
  final double y;

  CategoryChartData(this.x, this.y);
}

class NumericChartData {
  final double x;
  final double y;

  NumericChartData(this.x, this.y);
}
