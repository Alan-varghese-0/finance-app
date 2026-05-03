import 'package:cloud_firestore/cloud_firestore.dart';

/// All app data for a signed-in user lives under `users/{uid}/...`.
class UserFirestore {
  UserFirestore(this.uid);

  final String uid;

  DocumentReference<Map<String, dynamic>> get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get expenses =>
      userDoc.collection('expenses');

  CollectionReference<Map<String, dynamic>> get subscriptions =>
      userDoc.collection('subscriptions');

  CollectionReference<Map<String, dynamic>> get splits =>
      userDoc.collection('splits');

  CollectionReference<Map<String, dynamic>> get goals =>
      userDoc.collection('goals');

  CollectionReference<Map<String, dynamic>> get people =>
      userDoc.collection('people');
}
