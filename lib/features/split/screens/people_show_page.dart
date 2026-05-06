import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/repositories/firestore_user.dart';
import 'package:finance_app/features/split/split_self_person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import 'person_split_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Not signed in")));
    }

    final peopleRef = UserFirestore(uid).people;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("People"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: peopleRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No people added"));
          }

          // Sort: self first
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              final aa = a.data() as Map<String, dynamic>;
              final bb = b.data() as Map<String, dynamic>;

              final sa = aa['isSelf'] == true ? 0 : 1;
              final sb = bb['isSelf'] == true ? 0 : 1;

              if (sa != sb) return sa.compareTo(sb);

              return (aa['name'] ?? '').toString().compareTo(
                (bb['name'] ?? '').toString(),
              );
            });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _personCard(
                context,
                doc.id,
                data['name'] ?? '',
                isSelf: data['isSelf'] == true,
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddPersonDialog(context, uid),
      ),
    );
  }

  // 🔥 PERSON CARD
  Widget _personCard(
    BuildContext context,
    String docId,
    String name, {
    required bool isSelf,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PersonSplitPage(personName: name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isSelf
                  ? AppColors.primary.withOpacity(0.25)
                  : AppColors.primary.withOpacity(0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelf ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isSelf ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelf)
                    Text(
                      "You",
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                ],
              ),
            ),

            if (!isSelf)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Person'),
                      content: Text('Delete "$name"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && uid != null) {
                    await UserFirestore(uid).people.doc(docId).delete();

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('"$name" deleted')));
                  }
                },
              ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ➕ ADD PERSON DIALOG
  void _showAddPersonDialog(BuildContext context, String uid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Person"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              await UserFirestore(uid).people.add({
                'name': name,
                'isSelf': false,
                'createdAt': Timestamp.now(),
              });

              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
