// ignore_for_file: unused_local_variable

import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSplitScreen extends StatefulWidget {
  const AddSplitScreen({super.key});

  @override
  State<AddSplitScreen> createState() => _AddSplitScreenState();
}

class _AddSplitScreenState extends State<AddSplitScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  final peopleCollection = FirebaseFirestore.instance.collection('people');
  final splitCollection = FirebaseFirestore.instance.collection('splits');

  Map<String, bool> selectedPeople = {};
  Map<String, TextEditingController> customAmounts = {};
  Set<String> paidBy = {};
  bool isEqualSplit = true;

  /// 💾 SAVE WITH OWE LOGIC
  void saveSplit() async {
    final title = titleController.text;
    final totalAmount = double.tryParse(amountController.text) ?? 0;

    final selected = selectedPeople.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (title.isEmpty ||
        totalAmount == 0 ||
        selected.isEmpty ||
        paidBy.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    List<Map<String, dynamic>> peopleData = [];
    Map<String, double> owes = {};

    // Calculate total paid by all payers
    final payers = paidBy.toList();
    double payerShare = totalAmount / payers.length;

    /// ✅ EQUAL SPLIT
    if (isEqualSplit) {
      double each = totalAmount / selected.length;

      for (var name in selected) {
        peopleData.add({"name": name, "amount": each});

        if (!paidBy.contains(name)) {
          owes[name] = each;
        }
      }
    }
    /// ✅ CUSTOM SPLIT
    else {
      double sum = 0;

      for (var name in selected) {
        double amt = double.tryParse(customAmounts[name]?.text ?? "0") ?? 0;

        sum += amt;

        peopleData.add({"name": name, "amount": amt});

        if (!paidBy.contains(name)) {
          owes[name] = amt;
        }
      }

      if (sum != totalAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Amounts must match total")),
        );
        return;
      }
    }

    /// 🔥 FORMAT OWE LIST
    List<Map<String, dynamic>> oweList = [];
    for (var oweEntry in owes.entries) {
      // Split what each person owes among all payers
      double splitAmount = oweEntry.value / payers.length;
      for (var payer in payers) {
        oweList.add({"from": oweEntry.key, "to": payer, "amount": splitAmount});
      }
    }

    await splitCollection.add({
      "title": title,
      "amount": totalAmount,
      "paidBy": payers,
      "people": peopleData,
      "owe": oweList,
      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Split"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SECTION: SPLIT DETAILS
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Split Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        prefixIcon: Icon(Icons.title),
                        helperText: "Eg. Dinner, Trip, Rent...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Total Amount",
                        prefixIcon: Icon(Icons.currency_rupee),
                        helperText: "Enter the total amount to split",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// SECTION: SPLIT TYPE
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Split Type",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEqualSplit
                                  ? AppColors.income
                                  : AppColors.surface,
                              foregroundColor: isEqualSplit
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                setState(() => isEqualSplit = true),
                            child: const Text("Equal"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isEqualSplit
                                  ? AppColors.expense
                                  : AppColors.surface,
                              foregroundColor: !isEqualSplit
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () =>
                                setState(() => isEqualSplit = false),
                            child: const Text("Custom"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// SECTION: PEOPLE & PAID BY
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: peopleCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    final people = docs
                        .map((e) => e['name'] as String)
                        .toList();

                    // INIT DEFAULT
                    for (var name in people) {
                      selectedPeople.putIfAbsent(name, () => false);
                      customAmounts.putIfAbsent(
                        name,
                        () => TextEditingController(),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Paid by",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: people.map((name) {
                            final isSelected = paidBy.contains(name);
                            return FilterChip(
                              label: Text(name),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withOpacity(
                                0.15,
                              ),
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    paidBy.add(name);
                                  } else {
                                    paidBy.remove(name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text(
                          "Split between",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: people.map((name) {
                            return FilterChip(
                              label: Text(name),
                              selected: selectedPeople[name] ?? false,
                              selectedColor: AppColors.primary.withOpacity(
                                0.15,
                              ),
                              backgroundColor: AppColors.surface,
                              labelStyle: TextStyle(
                                color: selectedPeople[name] == true
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: selectedPeople[name] == true
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: selectedPeople[name] == true
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  selectedPeople[name] = val;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        if (!isEqualSplit)
                          Column(
                            children: people
                                .where((name) => selectedPeople[name] == true)
                                .map((name) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    child: TextField(
                                      controller: customAmounts[name],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Amount for $name",
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(),
                                        helperText:
                                            "Enter custom amount for $name",
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: saveSplit,
                icon: const Icon(Icons.save),
                label: const Text("Save Split"),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
