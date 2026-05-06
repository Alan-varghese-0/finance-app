import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/split/screens/people_show_page.dart';
import 'package:finance_app/features/split/split_self_person.dart';
import 'package:finance_app/features/split/widget/split_details_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class SplitTab extends StatefulWidget {
  final CollectionReference splitCollection;

  const SplitTab({super.key, required this.splitCollection});

  @override
  State<SplitTab> createState() => _SplitTabState();
}

class _SplitTabState extends State<SplitTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ensureSplitSelfPerson(UserFirestore(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: widget.splitCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _bg(const CircularProgressIndicator());
        }

        final splits = snapshot.data!.docs;

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _splitOverview(splits),
              ),

              /// ➕ ADD PEOPLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PeoplePage()),
                      );
                    },
                    icon: const Icon(Icons.group),
                    label: const Text(
                      "View People",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 📜 SPLITS LIST
              Expanded(
                child: splits.isEmpty
                    ? Center(
                        child: Text(
                          "No splits yet",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: splits.length,
                        itemBuilder: (ctx, i) {
                          final doc = splits[i];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};

                          return _splitItem(
                            doc: doc,
                            data: data,
                            onDelete: () =>
                                widget.splitCollection.doc(doc.id).delete(),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔥 OVERVIEW
  Widget _splitOverview(List<QueryDocumentSnapshot> splits) {
    double youOwe = 0;
    double youGet = 0;

    final selfName = splitSelfDisplayName(FirebaseAuth.instance.currentUser);

    for (var s in splits) {
      final data = s.data() as Map<String, dynamic>? ?? {};
      final owes = (data['owe'] ?? []) as List;

      for (var o in owes) {
        final from = o['from'];
        final to = o['to'];
        final amount = (o['amount'] ?? 0).toDouble();

        if (from == selfName) {
          youOwe += amount;
        } else if (to == selfName) {
          youGet += amount;
        }
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Split Overview",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "You get: ₹${youGet.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.green),
              ),

              Text(
                "You owe: ₹${youOwe.toStringAsFixed(0)}",
                style: const TextStyle(color: AppColors.expense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔥 SPLIT ITEM (SAFE + OWE LOGIC)
  Widget _splitItem({
    required QueryDocumentSnapshot doc,
    required Map<String, dynamic> data,
    required VoidCallback onDelete,
  }) {
    final people = (data['people'] ?? []) as List;
    final owes = (data['owe'] ?? []) as List;

    final peopleCount = people.length;

    /// 💥 SAFE OWE TEXT
    final selfName = splitSelfDisplayName(FirebaseAuth.instance.currentUser);

    List<Widget> oweWidgets = [];

    if (owes.isNotEmpty) {
      for (var e in owes) {
        final from = e['from'];
        final to = e['to'];
        final amount = e['amount'] ?? 0;

        final isYouPay = from == selfName;
        final isYouGet = to == selfName;

        Color color;
        String text;

        if (isYouGet) {
          text = "You get ₹$amount from $from";
          color = Colors.green;
        } else if (isYouPay) {
          text = "You owe ₹$amount to $to";
          color = AppColors.expense;
        } else {
          text = "$from owes $to ₹$amount";
          color = AppColors.textSecondary;
        }

        oweWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
        );
      }
    } else {
      oweWidgets.add(
        const Text(
          "No breakdown",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => SplitDetailsSheet(
              data: doc,
              selfName: splitSelfDisplayName(FirebaseAuth.instance.currentUser),
            ),
          ),

          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.expense.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group, color: AppColors.expense),
          ),

          title: Text(
            data['title'] ?? '',
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...oweWidgets,
              const SizedBox(height: 4),
              Text(
                "$peopleCount people",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          trailing: Text(
            "₹${data['amount'] ?? 0}",
            style: const TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ➕ ADD PERSON
  // ignore: unused_element
  void _showAddPersonDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Person"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await UserFirestore(uid).people.add({"name": name});
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _bg(Widget child) {
    return Container(
      color: AppColors.background,
      child: Center(child: child),
    );
  }
}
