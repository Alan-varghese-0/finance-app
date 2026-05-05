import 'package:finance_app/data/models/categories.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/expense.dart';
import '../models/category.dart';

enum ChartFilter { all, expense, income }

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

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
      data[bucket] ??= {
        TransactionType.expense: 0,
        TransactionType.income: 0,
      };

      data[bucket]![e.type] = (data[bucket]![e.type] ?? 0) + e.amount;
    }

    return data;
  }

  /// 🔥 FIX CATEGORY NAME
  String normalizeCategory(String name) {
    final n = name.toLowerCase().trim();
    if (n.contains('subscrib')) return 'Subscription';
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
    double total = 0;

    data.forEach((category, typeMap) {
      typeMap.forEach((type, amount) {
        if (amount <= 0) return;

        if (selectedFilter == ChartFilter.expense &&
            type != TransactionType.expense)
          return;

        if (selectedFilter == ChartFilter.income &&
            type != TransactionType.income)
          return;

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

        total += amount;
      });
    });

    if (chartData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No data for selected filter"),
      );
    }

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

          /// 🔥 FIXED CHART + SCROLLABLE LEGEND
          SizedBox(
            height: 300,
            child: Column(
              children: [
                /// 🥧 CHART (FIXED AREA)
                Expanded(
                  child: SfCircularChart(
                    tooltipBehavior: TooltipBehavior(enable: true),

                    /// ❌ Disable default legend
                    legend: const Legend(isVisible: false),

                    /// 🔥 Center Total
                    annotations: [
                      CircularChartAnnotation(
                        widget: Text(
                          "₹${total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                          final percent = (data.amount / total) * 100;
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
                        selectionBehavior: SelectionBehavior(enable: true),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// 📜 SCROLLABLE LEGEND (FIXED HEIGHT)
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
