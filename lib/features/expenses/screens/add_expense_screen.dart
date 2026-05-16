import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/categories.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/expenses/models/category.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:finance_app/features/expenses/widgets/map.dart';
import 'package:finance_app/theme/theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? id;
  final String? title;
  final double? amount;
  final DateTime? date;
  final String? type;
  final String? category;
  final String? location;

  const AddExpenseScreen({
    super.key,
    this.id,
    this.title,
    this.amount,
    this.date,
    this.type,
    this.category,
    this.location,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;

  DateTime selectedDate = DateTime.now();
  String selectedType = 'expense';
  CategoryModel? selectedCategory;

  /// LOCATION
  LatLng selectedLocation = LatLng(0, 0);

  String selectedLocationAddress = 'Tap to choose location';

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title ?? '');

    amountController = TextEditingController(
      text: widget.amount?.toString() ?? '',
    );

    selectedDate = widget.date ?? DateTime.now();

    selectedType = widget.type ?? 'expense';

    /// RESTORE CATEGORY
    if (widget.category != null) {
      final t = selectedType == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      final resolved = canonicalCategoryName(widget.category!, t);

      selectedCategory = categories.firstWhere(
        (c) => c.name == resolved,
        orElse: () => categories.first,
      );
    }

    _getCurrentLocation();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  List<CategoryModel> get filteredCategories {
    return categories
        .where((c) => c.type == selectedType && c.pickable)
        .toList();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });

      await _getAddressFromCoordinates(selectedLocation);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final address = '${place.street}, ${place.locality}';

        setState(() {
          selectedLocationAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        selectedLocationAddress =
            '${latLng.latitude.toStringAsFixed(4)}, '
            '${latLng.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveExpense() async {
    if (titleController.text.isEmpty ||
        amountController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not signed in")));
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid amount")));
      return;
    }

    final collection = UserFirestore(uid).expenses;

    final payload = <String, dynamic>{
      'userId': uid,
      'title': titleController.text.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(selectedDate),
      'type': selectedType,
      'category': selectedCategory!.name,

      /// LOCATION
      'location':
          '${selectedLocation.latitude},'
          '${selectedLocation.longitude}',

      'locationAddress': selectedLocationAddress,
    };

    /// USER DOC
    final userRef = UserFirestore(uid).userDoc;

    final userSnap = await userRef.get();

    double currentBalance = ((userSnap.data()?['balance'] ?? 0.0) as num)
        .toDouble();

    /// UPDATE BALANCE
    if (selectedType == 'expense') {
      currentBalance -= amount;
    } else {
      currentBalance += amount;
    }

    /// SAVE BALANCE
    await userRef.set({'balance': currentBalance}, SetOptions(merge: true));

    /// SAVE TRANSACTION
    if (widget.id == null) {
      await collection.doc().set(payload);
    } else {
      await collection.doc(widget.id).set(payload, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _openLocationPicker() async {
    /// GET CURRENT LOCATION BEFORE OPENING MAP
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      selectedLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint(e.toString());
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: selectedLocation),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        selectedLocation = result;
      });

      await _getAddressFromCoordinates(selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Transaction" : "Add Transaction"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// TITLE
            TextField(
              controller: titleController,

              style: const TextStyle(color: AppColors.textPrimary),

              decoration: const InputDecoration(
                labelText: "Title",
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),

            /// AMOUNT
            TextField(
              controller: amountController,

              keyboardType: TextInputType.number,

              style: const TextStyle(color: AppColors.textPrimary),

              decoration: const InputDecoration(
                labelText: "Amount",
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),

            const SizedBox(height: 16),

            /// LOCATION
            InkWell(
              onTap: _openLocationPicker,

              child: Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            selectedLocationAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// TYPE TOGGLE
            Container(
              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),

              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = 'income';

                          selectedCategory = null;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),

                        padding: const EdgeInsets.symmetric(vertical: 12),

                        decoration: BoxDecoration(
                          color: selectedType == 'income'
                              ? AppColors.income
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Center(
                          child: Text(
                            "Income",

                            style: TextStyle(
                              fontWeight: FontWeight.w600,

                              color: selectedType == 'income'
                                  ? Colors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = 'expense';

                          selectedCategory = null;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),

                        padding: const EdgeInsets.symmetric(vertical: 12),

                        decoration: BoxDecoration(
                          color: selectedType == 'expense'
                              ? AppColors.expense
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Center(
                          child: Text(
                            "Expense",

                            style: TextStyle(
                              fontWeight: FontWeight.w600,

                              color: selectedType == 'expense'
                                  ? Colors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CATEGORY
            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: filteredCategories.map((cat) {
                final isSelected = selectedCategory == cat;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withOpacity(0.2)
                          : AppColors.surface,

                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: isSelected ? cat.color : AppColors.border,
                      ),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),

                        const SizedBox(width: 6),

                        Text(
                          cat.name,

                          style: TextStyle(
                            color: isSelected
                                ? cat.color
                                : AppColors.textPrimary,

                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            /// DATE
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
                          DateFormat.yMMMd().format(selectedDate),

                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),

                    const Text(
                      "Change",
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedType == 'income'
                      ? AppColors.income
                      : AppColors.expense,

                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),

                onPressed: saveExpense,

                child: Text(
                  isEdit ? "Update" : "Add Transaction",

                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
