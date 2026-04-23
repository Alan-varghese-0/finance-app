import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'person_split_page.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final peopleRef = FirebaseFirestore.instance.collection('people');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("People"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: peopleRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final people = snapshot.data!.docs;

          if (people.isEmpty) {
            return const Center(child: Text("No people added"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: people.length,
            itemBuilder: (context, index) {
              final doc = people[index];
              final data = doc.data() as Map<String, dynamic>;

              return _personCard(context, data['name'] ?? '');
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddPersonDialog(context),
      ),
    );
  }

  Widget _personCard(BuildContext context, String name) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PersonSplitPage(personName: name)),
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context) {
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
}
