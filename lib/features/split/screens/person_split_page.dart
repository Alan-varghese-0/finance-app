import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/firestore_user.dart';
import 'package:finance_app/features/split/split_self_person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class PersonSplitPage extends StatelessWidget {
  final String personName;

  const PersonSplitPage({super.key, required this.personName});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Not signed in")));
    }

    final splitRef = UserFirestore(uid).splits;
    final selfName = splitSelfDisplayName(FirebaseAuth.instance.currentUser);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(personName == selfName ? 'You' : personName),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: splitRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSplits = snapshot.data!.docs;

          /// 🔥 FILTER USING `owe`
          final personSplits = allSplits.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final owes = (data['owe'] ?? []) as List;
            return owes.any(
              (e) => e['from'] == personName || e['to'] == personName,
            );
          }).toList();

          if (personSplits.isEmpty) {
            return Center(child: Text("No splits for $personName"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: personSplits.length,
            itemBuilder: (context, index) {
              final doc = personSplits[index];
              final data = doc.data() as Map<String, dynamic>;

              // Compute status and color for this split
              String status = '';
              Color color = AppColors.textSecondary;
              final owes = (data['owe'] ?? []) as List;
              for (final e in owes) {
                final from = e['from']?.toString() ?? '';
                final to = e['to']?.toString() ?? '';
                final toLabel = to == selfName ? 'You' : to;
                final fromLabel = from == selfName ? 'You' : from;

                if (from == personName) {
                  if (personName == selfName) {
                    status = 'You owe $toLabel ₹${e['amount']}';
                  } else {
                    status = '$personName owes $toLabel ₹${e['amount']}';
                  }
                  color = AppColors.expense;
                  break;
                } else if (to == personName) {
                  if (personName == selfName) {
                    status = '$fromLabel owes you ₹${e['amount']}';
                  } else {
                    status = '$fromLabel owes $personName ₹${e['amount']}';
                  }
                  color = AppColors.income;
                  break;
                }
              }

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await splitRef.doc(personSplits[index].id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Split deleted")),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "₹${data['amount'] ?? 0}",
                        style: const TextStyle(color: AppColors.expense),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Split"),
                      content: const Text("Are you sure?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
