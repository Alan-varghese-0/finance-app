import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/data/models/categories.dart';
import 'package:finance_app/features/expenses/models/category.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:finance_app/theme/theme.dart';

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

  // Location variables
  GoogleMapController? mapController;
  LatLng selectedLocation = const LatLng(
    20.5937,
    78.9629,
  ); // Default: India center
  String selectedLocationAddress = 'Tap map to select location';
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title ?? '');
    amountController = TextEditingController(
      text: widget.amount?.toString() ?? '',
    );

    selectedDate = widget.date ?? DateTime.now();
    selectedType = widget.type ?? 'expense';

    /// restore category if editing
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

    /// Initialize location
    _getCurrentLocation();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  List<CategoryModel> get filteredCategories {
    return categories
        .where((c) => c.type == selectedType && c.pickable)
        .toList();
  }

  IconData getIcon(String name) {
    switch (name) {
      case "restaurant":
        return Icons.restaurant;
      case "directions_car":
        return Icons.directions_car;
      case "shopping_bag":
        return Icons.shopping_bag;
      case "receipt":
        return Icons.receipt;
      case "favorite":
        return Icons.favorite;
      case "movie":
        return Icons.movie;
      case "account_balance_wallet":
        return Icons.account_balance_wallet;
      case "laptop":
        return Icons.laptop;
      case "business_center":
        return Icons.business_center;
      case "trending_up":
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          selectedLocationAddress = 'Location permission denied';
        });
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
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address =
            '${place.street}, ${place.locality}, ${place.postalCode}';
        setState(() {
          selectedLocationAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        selectedLocationAddress =
            '${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}';
      });
    }
  }

  void _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: selectedLocation,
          onLocationSelected: _updateSelectedLocation,
        ),
      ),
    );
  }

  Future<void> _updateSelectedLocation(LatLng newLocation) async {
    setState(() {
      selectedLocation = newLocation;
    });
    await _getAddressFromCoordinates(newLocation);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
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
      'location':
          '${selectedLocation.latitude.toStringAsFixed(6)},${selectedLocation.longitude.toStringAsFixed(6)}',
      'locationAddress': selectedLocationAddress,
    };

    /// USER DOC
    final userRef = UserFirestore(uid).userDoc;

    /// CURRENT USER DATA
    final userSnap = await userRef.get();

    double currentBalance = ((userSnap.data()?['balance'] ?? 0.0) as num)
        .toDouble();

    /// UPDATE BALANCE
    if (selectedType == 'expense') {
      currentBalance -= amount;
    } else {
      currentBalance += amount;
    }

    /// SAVE UPDATED BALANCE
    await userRef.set({'balance': currentBalance}, SetOptions(merge: true));

    /// SAVE TRANSACTION
    if (widget.id == null) {
      await collection.doc().set(payload);
    } else {
      await collection.doc(widget.id).set(payload, SetOptions(merge: true));
    }

    Navigator.pop(context);
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

            /// LOCATION PICKER
            InkWell(
              onTap: _openLocationPicker,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 8),
                    Text(
                      '${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 TYPE TOGGLE
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

            /// 🔥 CATEGORY CHIPS WITH ALIGNMENT
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selectedType == 'income'
                    ? AppColors.income.withOpacity(0.05)
                    : AppColors.expense.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: selectedType == 'income'
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: selectedType == 'income'
                      ? WrapAlignment.start
                      : WrapAlignment.end,
                  children: filteredCategories.map((cat) {
                    final isSelected = selectedCategory == cat;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedCategory = cat);
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
                            width: 1.5,
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
              ),
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
                          style: TextStyle(color: AppColors.textPrimary),
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

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerScreen({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  late LatLng selectedLocation;
  late Set<Marker> markers;

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
    markers = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: selectedLocation,
        infoWindow: const InfoWindow(title: 'Selected Location'),
      ),
    };
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      selectedLocation = position;
      markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: selectedLocation,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });
  }

  void _confirmLocation() {
    widget.onLocationSelected(selectedLocation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location'), centerTitle: true),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 15,
            ),
            onTap: _onMapTapped,
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Coordinates:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmLocation,
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
