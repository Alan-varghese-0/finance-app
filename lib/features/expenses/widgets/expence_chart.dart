import 'package:finance_app/data/models/categories.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/expense.dart';
import '../models/category.dart';

enum ChartFilter { all, expense, income }

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;

  /// 🔥 CURRENT BALANCE
  final double currentBalance;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.currentBalance,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  ChartFilter selectedFilter = ChartFilter.all;

  /// 🔥 GROUP DATA
  Map<String, Map<TransactionType, double>> getCategoryTotals() {
    final Map<String, Map<TransactionType, double>> data = {};

    for (var e in widget.expenses) {
      final bucket = canonicalCategoryName(e.category, e.type);

      data[bucket] ??= {TransactionType.expense: 0, TransactionType.income: 0};

      data[bucket]![e.type] = (data[bucket]![e.type] ?? 0) + e.amount;
    }

    return data;
  }

  /// 🔥 FIX CATEGORY NAME
  String normalizeCategory(String name) {
    final n = name.toLowerCase().trim();

    if (n.contains('subscrib')) {
      return 'Subscription';
    }

    return name;
  }

  /// 🔥 SAFE CATEGORY FETCH
  CategoryModel getCategory(String name) {
    final normalizedName = normalizeCategory(name).toLowerCase().trim();

    return categories.firstWhere(
      (c) => c.name.toLowerCase().trim() == normalizedName,
      orElse: () => CategoryModel(
        name: name,
        color: const Color(0xFF888888),
        icon: Icons.help_outline,
        type: "expense",
      ),
    );
  }

  /// 🔥 FORMAT MONEY
  String formatAmount(double amount) {
    if (amount >= 10000000) {
      return "₹${(amount / 10000000).toStringAsFixed(1)}Cr";
    }

    if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(1)}L";
    }

    if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}K";
    }

    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    final data = getCategoryTotals();

    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No transaction data"),
      );
    }

    /// 🔥 PREPARE CHART DATA
    final chartData = <_ChartData>[];

    data.forEach((category, typeMap) {
      typeMap.forEach((type, amount) {
        if (amount <= 0) return;

        if (selectedFilter == ChartFilter.expense &&
            type != TransactionType.expense) {
          return;
        }

        if (selectedFilter == ChartFilter.income &&
            type != TransactionType.income) {
          return;
        }

        final cat = getCategory(category);

        final baseColor = cat.color;

        final color = type == TransactionType.expense
            ? baseColor
            : baseColor.withOpacity(0.5);

        chartData.add(
          _ChartData(
            name: "${cat.name} ${type == TransactionType.expense ? '↓' : '↑'}",
            amount: amount,
            color: color,
          ),
        );
      });
    });

    /// 🔥 CURRENT BALANCE
    final total = widget.currentBalance;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 FILTER CHIPS
          Row(
            children: ChartFilter.values.map((filter) {
              final isSelected = selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filter.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.white,
                  backgroundColor: Colors.grey[800],
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          /// 🔥 CHART
          SizedBox(
            height: 300,
            child: Column(
              children: [
                /// 🥧 CHART
                Expanded(
                  child: chartData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.pie_chart_outline,
                                color: Colors.white54,
                                size: 50,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "No data for selected filter",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SfCircularChart(
                          tooltipBehavior: TooltipBehavior(enable: true),

                          legend: const Legend(isVisible: false),

                          /// 🔥 CENTER BALANCE
                          annotations: [
                            CircularChartAnnotation(
                              widget: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text(
                                        "Current Balance",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        "₹${total.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Balance",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatAmount(total),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          series: <CircularSeries>[
                            DoughnutSeries<_ChartData, String>(
                              dataSource: chartData,

                              xValueMapper: (data, _) => data.name,

                              yValueMapper: (data, _) => data.amount,

                              pointColorMapper: (data, _) => data.color,

                              dataLabelMapper: (data, _) {
                                double visibleTotal = 0;

                                for (var item in chartData) {
                                  visibleTotal += item.amount;
                                }

                                final percent =
                                    (data.amount / visibleTotal) * 100;

                                return "${percent.toStringAsFixed(0)}%";
                              },

                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              animationDuration: 1200,
                              innerRadius: '55%',
                              selectionBehavior: SelectionBehavior(
                                enable: true,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 10),

                /// 📜 LEGEND
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: Colors.white54,
                    ),

                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chartData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = chartData[index];

                            return Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  item.name,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 INTERNAL MODEL
class _ChartData {
  final String name;
  final double amount;
  final Color color;

  _ChartData({required this.name, required this.amount, required this.color});
}
