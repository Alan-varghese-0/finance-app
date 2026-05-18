import 'package:flutter/material.dart';
import 'package:finance_app/features/expenses/screens/add_expense_screen.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:intl/intl.dart';

class ExpenseDetailPage extends StatelessWidget {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;
  final String category;
  final String source;
  final String? location;
  final String? receiptUrl;

  const ExpenseDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    required this.source,
    this.location,
    this.receiptUrl,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().format(date);
    final formattedTime = DateFormat.jm().format(date);
    final canEdit = source == 'expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (receiptUrl != null && receiptUrl!.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      receiptUrl!,
                      fit: BoxFit.cover,
                      height: 250,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 250,
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: type == 'income'
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _detailRow('Type', type.capitalize()),
                    const SizedBox(height: 12),
                    _detailRow('Category', category),
                    const SizedBox(height: 12),
                    _detailRow('Date', formattedDate),
                    const SizedBox(height: 12),
                    _detailRow('Time', formattedTime),
                    if (location != null && location!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _detailRow('Location', location!),
                    ],
                    const SizedBox(height: 12),
                    _detailRow('Source', source),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (canEdit)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Transaction'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(
                          id: id,
                          title: title,
                          amount: amount,
                          date: date,
                          type: type,
                          category: category,
                          receiptUrl: receiptUrl,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

extension StringUtils on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
