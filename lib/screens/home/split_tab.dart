import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/widgets/split_details_screens.dart';
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
              /// 🔥 OVERVIEW
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showAddPersonDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Add People"),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// 📜 LIST
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
                          final data = doc.data() as Map<String, dynamic>;

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

  /// 🔥 OVERVIEW CARD
  Widget _splitOverview(List<QueryDocumentSnapshot> splits) {
    double total = 0;

    for (var s in splits) {
      final data = s.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Split Overview",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            "₹${total.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SPLIT ITEM (WITH OWE LOGIC)
  Widget _splitItem({
    required QueryDocumentSnapshot doc,
    required Map<String, dynamic> data,
    required VoidCallback onDelete,
  }) {
    final peopleCount = data['people']?.length ?? 0;
    final List owes = data['owe'] ?? [];

    /// 💥 OWE TEXT
    String oweText = "";
    if (owes.isNotEmpty) {
      oweText = owes
          .map((e) => "${e['from']} → ${e['to']} ₹${e['amount']}")
          .join(", ");
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
            builder: (_) => SplitDetailsSheet(data: doc),
          ),

          /// ICON
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.expense.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group, color: AppColors.expense),
          ),

          /// TITLE
          title: Text(
            data['title'] ?? '',
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          /// 🔥 OWE + PEOPLE
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (oweText.isNotEmpty)
                Text(
                  oweText,
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
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

          /// AMOUNT
          trailing: Text(
            "₹${data['amount']}",
            style: const TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// ➕ ADD PERSON DIALOG
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
                await FirebaseFirestore.instance.collection('people').add({
                  "name": name,
                });
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
