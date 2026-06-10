import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Map<String, dynamic>? get userData => _userData;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUserDoc(user.uid);
      } else {
        _userSubscription?.cancel();
        _userData = null;
        notifyListeners();
      }
    });
  }

  void _listenToUserDoc(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
