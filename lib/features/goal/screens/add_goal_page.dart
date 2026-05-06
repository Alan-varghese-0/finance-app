import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddGoalPage extends StatefulWidget {
  const AddGoalPage({super.key});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

  int priority = 3;
  DateTime? deadline;

  /// 🎨 SAME COLOR SYSTEM (SYNC WITH WIDGET)
  Color priorityColor(int p) {
    if (p >= 5) return const Color(0xFFE53935); // red
    if (p == 4) return const Color(0xFFFF7043); // orange
    if (p == 3) return const Color(0xFFFFCA28); // amber
    if (p == 2) return const Color(0xFF42A5F5); // blue
    return const Color(0xFF66BB6A); // green
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => deadline = picked);
    }
  }

  Future<void> saveGoal() async {
    if (titleCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await UserFirestore(uid).goals.doc().set({
      "userId": uid,
      "title": titleCtrl.text,
      "targetAmount": int.parse(amountCtrl.text),
      "savedAmount": 0,
      "priority": priority,
      "createdAt": Timestamp.now(),
      "deadline": deadline != null ? Timestamp.fromDate(deadline!) : null,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Add Goal"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 TITLE
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: "Goal Title",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.flag, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 AMOUNT
            TextField(
              controller: amountCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Target Amount",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 PRIORITY SELECTOR (COLORED)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 10,
                children: List.generate(5, (i) {
                  final p = i + 1;
                  final isSelected = p == priority;
                  final color = priorityColor(p);

                  return GestureDetector(
                    onTap: () => setState(() => priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(
                            "P$p",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            /// 📅 DEADLINE
            InkWell(
              onTap: pickDate,
              child: Container(
                height: 75,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          deadline == null
                              ? "Set Deadline"
                              : DateFormat.yMMMd().format(deadline!),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Text(
                      "Pick",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ✅ BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveGoal,
                child: const Text("Create Goal"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
