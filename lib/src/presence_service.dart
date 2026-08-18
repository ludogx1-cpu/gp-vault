import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();

  factory PresenceService() {
    return _instance;
  }

  PresenceService._internal();

  void initialize() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _setupPresence(user.uid);
      }
    });
  }

  void _setupPresence(String uid) {
    try {
      final DatabaseReference connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      final DatabaseReference myStatusRef = FirebaseDatabase.instance.ref('status/$uid');

      connectedRef.onValue.listen((event) {
        final isConnected = event.snapshot.value as bool? ?? false;
        if (isConnected) {
          // When connected, set up an onDisconnect handler to mark offline if we lose connection
          myStatusRef.onDisconnect().update({
            'state': 'offline',
            'last_changed': ServerValue.timestamp,
          }).then((_) {
            // Once the onDisconnect is queued on the server, we mark ourselves online
            myStatusRef.update({
              'state': 'online',
              'last_changed': ServerValue.timestamp,
            });
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up RTDB presence: $e');
      }
    }
  }
}
