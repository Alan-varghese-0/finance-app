import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/data/firestore_user.dart';

/// Display name used in split `people` / `owe` so settlements match the signed-in user.
String splitSelfDisplayName(User? user) {
  if (user == null) return 'Me';
  final dn = user.displayName?.trim();
  if (dn != null && dn.isNotEmpty) return dn;
  final email = user.email?.trim();
  if (email != null && email.contains('@')) {
    return email.split('@').first;
  }
  return 'Me';
}

/// Ensures `users/{uid}/people` has exactly one document with `isSelf: true` (the default "you" row).
Future<void> ensureSplitSelfPerson(UserFirestore fs) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final name = splitSelfDisplayName(user);
  final existing =
      await fs.people.where('isSelf', isEqualTo: true).limit(1).get();

  if (existing.docs.isEmpty) {
    await fs.people.add({
      'name': name,
      'isSelf': true,
      'userId': fs.uid,
    });
    return;
  }

  final doc = existing.docs.first;
  final cur = doc.data()['name'] as String?;
  if (cur != name) {
    await doc.reference.update({'name': name});
  }
}
