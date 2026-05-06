import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
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
        title: Text(
          personName == selfName ? 'You' : personName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: splitRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allSplits = snapshot.data!.docs;

          final personSplits = allSplits.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final owes = (data['owe'] ?? []) as List;
            return owes.any(
              (e) => e['from'] == personName || e['to'] == personName,
            );
          }).toList();

          if (personSplits.isEmpty) {
            return Center(
              child: Text(
                "No splits for $personName",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            itemCount: personSplits.length,
            itemBuilder: (context, index) {
              final doc = personSplits[index];
              final data = doc.data() as Map<String, dynamic>;

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
                  color = AppColors.income;
                  break;
                } else if (to == personName) {
                  if (personName == selfName) {
                    status = '$fromLabel owes you ₹${e['amount']}';
                  } else {
                    status = '$fromLabel owes $personName ₹${e['amount']}';
                  }
                  color = AppColors.expense;
                  break;
                }
              }

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 28),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (_) async {
                  await splitRef.doc(personSplits[index].id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Split deleted")),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "₹${data['amount'] ?? 0}",
                            style: TextStyle(
                              color: AppColors.expense.withOpacity(0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
