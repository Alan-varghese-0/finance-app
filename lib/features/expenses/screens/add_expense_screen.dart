import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finance_app/data/models/categories.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/expenses/models/category.dart';
import 'package:finance_app/features/expenses/models/expense.dart';
import 'package:finance_app/features/expenses/widgets/map.dart';
import 'package:finance_app/services/cloudinary_service.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? id;
  final String? title;
  final double? amount;
  final DateTime? date;
  final String? type;
  final String? category;
  final String? location;
  final String? receiptUrl;

  const AddExpenseScreen({
    super.key,
    this.id,
    this.title,
    this.amount,
    this.date,
    this.type,
    this.category,
    this.location,
    this.receiptUrl,
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

  bool isLoadingLocation = true;

  /// LOCATION
  LatLng selectedLocation = const LatLng(0, 0);

  String selectedLocationAddress = "Fetching location...";

  /// RECEIPT
  File? selectedReceiptFile;

  String? uploadedReceiptUrl;
  String? uploadedReceiptPublicId;

  bool isUploadingReceipt = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title ?? '');

    amountController = TextEditingController(
      text: widget.amount?.toString() ?? '',
    );

    selectedDate = widget.date ?? DateTime.now();

    selectedType = widget.type ?? 'expense';

    uploadedReceiptUrl = widget.receiptUrl;
    uploadedReceiptPublicId = widget.receiptUrl != null
        ? CloudinaryService.extractPublicIdFromUrl(widget.receiptUrl!)
        : null;

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

    _initializeLocation();
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

  /// LOCATION
  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          selectedLocationAddress = "Location service disabled";

          isLoadingLocation = false;
        });

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          selectedLocationAddress = "Location permission denied";

          isLoadingLocation = false;
        });

        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      selectedLocation = LatLng(position.latitude, position.longitude);

      await _getAddressFromCoordinates(selectedLocation);

      setState(() {
        isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        selectedLocationAddress = "Unable to fetch location";

        isLoadingLocation = false;
      });
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

        String address = "";

        if (place.street != null && place.street!.isNotEmpty) {
          address += "${place.street}, ";
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          address += "${place.locality}, ";
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += place.administrativeArea!;
        }

        setState(() {
          selectedLocationAddress = address;
        });
      }
    } catch (e) {
      setState(() {
        selectedLocationAddress =
            "${latLng.latitude.toStringAsFixed(4)}, "
            "${latLng.longitude.toStringAsFixed(4)}";
      });
    }
  }

  /// DATE
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

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );

      if (picked == null) return;

      setState(() {
        selectedReceiptFile = File(picked.path);
      });

      await uploadReceipt();
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImageFromGallery() async {
    await pickImage(ImageSource.gallery);
  }

  Future<void> pickImageFromCamera() async {
    await pickImage(ImageSource.camera);
  }

  Future<void> pickDocumentFile() async {
    try {
      final result = await FilePicker.pickFiles();

      if (result == null) return;

      final path = result.files.single.path;

      if (path == null) return;

      setState(() {
        selectedReceiptFile = File(path);
      });

      await uploadReceipt();
    } catch (e) {
      print(e);
    }
  }

  Future<void> removeReceipt() async {
    if (uploadedReceiptPublicId != null) {
      await CloudinaryService.deleteImage(uploadedReceiptPublicId!);
    } else if (uploadedReceiptUrl != null) {
      final publicId = CloudinaryService.extractPublicIdFromUrl(
        uploadedReceiptUrl!,
      );
      if (publicId != null) {
        await CloudinaryService.deleteImage(publicId);
      }
    }

    setState(() {
      selectedReceiptFile = null;
      uploadedReceiptUrl = null;
      uploadedReceiptPublicId = null;
    });
  }

  Future<void> uploadReceipt() async {
    if (selectedReceiptFile == null) return;

    try {
      setState(() {
        isUploadingReceipt = true;
      });

      final result = await CloudinaryService.uploadImage(selectedReceiptFile!);

      if (result != null) {
        uploadedReceiptUrl = result.url;
        uploadedReceiptPublicId = result.publicId;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Receipt uploaded")));
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isUploadingReceipt = false;
      });
    }
  }

  /// SAVE
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

      'location': '${selectedLocation.latitude},${selectedLocation.longitude}',

      'locationAddress': selectedLocationAddress,
      'receiptUrl': uploadedReceiptUrl,
      'receiptPublicId': uploadedReceiptPublicId,
    };

    final userRef = UserFirestore(uid).userDoc;

    final userSnap = await userRef.get();

    double currentBalance = ((userSnap.data()?['balance'] ?? 0.0) as num)
        .toDouble();

    if (selectedType == 'expense') {
      currentBalance -= amount;
    } else {
      currentBalance += amount;
    }

    await userRef.set({'balance': currentBalance}, SetOptions(merge: true));

    if (widget.id == null) {
      await collection.doc().set(payload);
    } else {
      await collection.doc(widget.id).set(payload, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// MAP PICKER
  Future<void> _openLocationPicker() async {
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

              decoration: const InputDecoration(
                labelText: "Amount",
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),

            const SizedBox(height: 16),

            /// LOCATION
            InkWell(
              onTap: isLoadingLocation ? null : _openLocationPicker,

              child: Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: AppColors.border),
                ),

                child: Row(
                  children: [
                    const Icon(Icons.location_on),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        selectedLocationAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (isLoadingLocation)
                      const SizedBox(
                        height: 18,
                        width: 18,

                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// INCOME EXPENSE
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),

              padding: const EdgeInsets.all(6),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),

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
                        duration: const Duration(milliseconds: 400),

                        padding: const EdgeInsets.symmetric(vertical: 14),

                        decoration: BoxDecoration(
                          color: selectedType == 'income'
                              ? Colors.green.withOpacity(0.15)
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),

                          opacity: selectedType == 'income' ? 1 : 0.7,

                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 300),

                            offset: selectedType == 'income'
                                ? Offset.zero
                                : const Offset(-0.1, 0),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  color: selectedType == 'income'
                                      ? Colors.green
                                      : AppColors.textSecondary,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  "Income",

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    color: selectedType == 'income'
                                        ? Colors.green
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = 'expense';

                          selectedCategory = null;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),

                        padding: const EdgeInsets.symmetric(vertical: 14),

                        decoration: BoxDecoration(
                          color: selectedType == 'expense'
                              ? Colors.red.withOpacity(0.15)
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),

                          opacity: selectedType == 'expense' ? 1 : 0.7,

                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 300),

                            offset: selectedType == 'expense'
                                ? Offset.zero
                                : const Offset(0.1, 0),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: selectedType == 'expense'
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  "Expense",

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    color: selectedType == 'expense'
                                        ? Colors.red
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
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
            /// CATEGORY
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),

              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,

                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),

                    child: child,
                  ),
                );
              },

              child:
                  /// CATEGORY
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: filteredCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cat = entry.value;

                      final isSelected = selectedCategory == cat;

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 60)),
                        tween: Tween(begin: 0, end: 1),

                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (value * 0.1),

                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),

                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 20),

                                child: child,
                              ),
                            ),
                          );
                        },

                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },

                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),

                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withOpacity(0.18)
                                  : AppColors.surface,

                              borderRadius: BorderRadius.circular(22),

                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),

                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: cat.color.withOpacity(0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 250),
                                  scale: isSelected ? 1.15 : 1,

                                  child: Icon(
                                    cat.icon,
                                    size: 20,
                                    color: cat.color,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),

                                  style: TextStyle(
                                    color: isSelected
                                        ? cat.color
                                        : AppColors.textPrimary,

                                    fontWeight: FontWeight.bold,
                                    fontSize: isSelected ? 15 : 14,
                                  ),

                                  child: Text(cat.name),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: AppColors.border),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined),

                        const SizedBox(width: 10),

                        Text(DateFormat.yMMMd().format(selectedDate)),
                      ],
                    ),

                    const Text("Change"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// RECEIPT PICKER
            Container(
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: AppColors.border),
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          uploadedReceiptUrl != null
                              ? "Receipt Attached"
                              : "Add Receipt / Bill",

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickImageFromGallery,
                          icon: const Icon(Icons.image),
                          label: const Text("Gallery"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickDocumentFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text("File"),
                        ),
                      ),
                    ],
                  ),

                  if (isUploadingReceipt)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),

                  if (uploadedReceiptUrl != null) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        uploadedReceiptUrl!,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: AppColors.surface,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: AppColors.surface,
                          child: const Center(
                            child: Text('Failed to load image'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              await pickImageFromGallery();
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text("Change"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: removeReceipt,
                            icon: const Icon(Icons.delete),
                            label: const Text("Remove"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "✓ Receipt uploaded",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedType == 'income'
                      ? Colors.green
                      : Colors.red,

                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),

                onPressed: saveExpense,

                child: Text(
                  isEdit ? "Update Transaction" : "Add Transaction",

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
