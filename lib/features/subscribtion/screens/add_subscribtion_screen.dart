import 'package:finance_app/data/firestore_user.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String repeatType = "monthly";

  final List<String> repeatOptions = ["daily", "weekly", "monthly", "yearly"];

  void saveSubscription() async {
    if (titleController.text.isEmpty || amountController.text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await UserFirestore(uid).subscriptions.add({
      "userId": uid,
      "title": titleController.text,
      "amount": double.parse(amountController.text),
      "nextDate": selectedDate,
      "repeatType": repeatType,
      "createdAt": DateTime.now(),
    });

    Navigator.pop(context);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Subscription")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// TITLE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Subscription Name"),
            ),

            const SizedBox(height: 16),

            /// AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₹ ",
              ),
            ),

            const SizedBox(height: 20),

            /// DATE PICKER
            InkWell(
              onTap: pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Next Billing Date",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// REPEAT TYPE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Repeat",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              children: repeatOptions.map((type) {
                final selected = repeatType == type;

                return ChoiceChip(
                  label: Text(type.toUpperCase()),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => repeatType = type);
                  },
                  selectedColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.background
                        : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.background,
                  backgroundColor: AppColors.expense,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: saveSubscription,
                child: const Text("Save Subscription"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
