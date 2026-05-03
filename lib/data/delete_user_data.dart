import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/firestore_user.dart';

/// Deletes `users/{uid}` data the app creates (subcollections + user doc).
Future<void> deleteUserFirestoreData(String uid) async {
  final fs = UserFirestore(uid);
  final db = FirebaseFirestore.instance;

  Future<void> deleteQuery(Query<Map<String, dynamic>> q) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    do {
      snap = await q.limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } while (snap.docs.length >= 400);
  }

  while (true) {
    final goalsSnap = await fs.goals.limit(100).get();
    if (goalsSnap.docs.isEmpty) break;
    for (final g in goalsSnap.docs) {
      await deleteQuery(g.reference.collection('transactions'));
      await g.reference.delete();
    }
  }

  await deleteQuery(fs.expenses);
  await deleteQuery(fs.subscriptions);
  await deleteQuery(fs.splits);
  await deleteQuery(fs.people);

  await fs.userDoc.delete();
}
