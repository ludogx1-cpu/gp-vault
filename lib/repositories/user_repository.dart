import 'package:cloud_firestore/cloud_firestore.dart';
class UserRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getUserData(String uid, {bool forceServer = false}) async {
    final options = forceServer ? const GetOptions(source: Source.server) : const GetOptions();
    final doc = await _db.collection('users').doc(uid).get(options);
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<void> skipProfileSetup() async {
    // Handled in SharedPreferences usually, but if we need a DB flag we can add it.
  }
}
