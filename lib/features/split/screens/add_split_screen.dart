// ignore_for_file: unused_local_variable

import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/split/split_self_person.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  late final UserFirestore _fs;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _fs = UserFirestore(uid);
    ensureSplitSelfPerson(_fs);
  }

  Map<String, bool> selectedPeople = {};

  /// 🔥 UPDATED CONTROLLERS
  Map<String, TextEditingController> shareControllers = {};
  Map<String, TextEditingController> paidControllers = {};

  Set<String> paidBy = {};
  bool isEqualSplit = true;

  /// 💾 SAVE SPLIT
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
        (isEqualSplit && paidBy.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    List<Map<String, dynamic>> peopleData = [];

    /// ✅ EQUAL SPLIT
    if (isEqualSplit) {
      final payers = paidBy.toList();
      double payerAmount = totalAmount / payers.length;
      double each = totalAmount / selected.length;

      for (var name in selected) {
        double paid = paidBy.contains(name) ? payerAmount : 0;

        peopleData.add({"name": name, "share": each, "paid": paid});
      }
    }
    /// ✅ CUSTOM SPLIT
    else {
      double totalShare = 0;
      double totalPaid = 0;

      for (var name in selected) {
        double share =
            double.tryParse(shareControllers[name]?.text ?? "0") ?? 0;
        double paid = double.tryParse(paidControllers[name]?.text ?? "0") ?? 0;

        totalShare += share;
        totalPaid += paid;

        peopleData.add({"name": name, "share": share, "paid": paid});
      }

      if ((totalShare - totalAmount).abs() > 0.01 ||
          (totalPaid - totalAmount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Total paid & share must equal total")),
        );
        return;
      }
    }

    /// 🔥 BALANCE CALCULATION
    List<Map<String, dynamic>> creditors = [];
    List<Map<String, dynamic>> debtors = [];

    for (var p in peopleData) {
      double balance = (p['paid'] as double) - (p['share'] as double);

      if (balance > 0) {
        creditors.add({"name": p['name'], "balance": balance});
      } else if (balance < 0) {
        debtors.add({"name": p['name'], "balance": -balance});
      }
    }

    /// 🔥 SMART SETTLEMENT
    List<Map<String, dynamic>> oweList = [];

    int i = 0, j = 0;

    while (i < debtors.length && j < creditors.length) {
      double debt = debtors[i]['balance'];
      double credit = creditors[j]['balance'];

      double amt = debt < credit ? debt : credit;

      oweList.add({
        "from": debtors[i]['name'],
        "to": creditors[j]['name'],
        "amount": amt.round(),
        "isPaid": false, // ✅ NEW
        "paidAt": null, // ✅ NEW
      });

      debtors[i]['balance'] -= amt;
      creditors[j]['balance'] -= amt;

      if (debtors[i]['balance'] == 0) i++;
      if (creditors[j]['balance'] == 0) j++;
    }

    await _fs.splits.doc().set({
      "userId": _fs.uid,
      "title": title,
      "amount": totalAmount,
      "paidBy": paidBy.toList(),
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
        backgroundColor: AppColors.background,

        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 SPLIT DETAILS
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

            /// 🔹 SPLIT TYPE
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

            /// 🔹 PEOPLE SECTION
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
                  stream: _fs.people.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final people = snapshot.data!.docs
                        .map((e) => e['name'] as String)
                        .toList();

                    /// INIT
                    for (var name in people) {
                      selectedPeople.putIfAbsent(name, () => false);
                      shareControllers.putIfAbsent(
                        name,
                        () => TextEditingController(),
                      );
                      paidControllers.putIfAbsent(
                        name,
                        () => TextEditingController(),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Paid by",
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                                  val ? paidBy.add(name) : paidBy.remove(name);
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: people.map((name) {
                            return FilterChip(
                              label: Text(
                                name,
                                style: TextStyle(
                                  color: selectedPeople[name] == true
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: selectedPeople[name] ?? false,
                              selectedColor: AppColors.primary.withOpacity(
                                0.15,
                              ),
                              backgroundColor: AppColors.surface,
                              onSelected: (val) {
                                setState(() {
                                  selectedPeople[name] = val;
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),

                        /// 🔥 NEW ROW UI (STYLED)
                        if (!isEqualSplit)
                          Column(
                            children: people
                                .where((n) => selectedPeople[n] == true)
                                .map((name) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            controller: shareControllers[name],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: "Share",
                                              prefixText: "₹ ",
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            controller: paidControllers[name],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: "Paid",
                                              prefixText: "₹ ",
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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

            const SizedBox(height: 30),

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
                ),
                onPressed: saveSplit,
                icon: const Icon(Icons.save),
                label: const Text("Save Split"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
