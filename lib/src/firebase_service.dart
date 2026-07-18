import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  static Future<void> initialize() async {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCDpj38AVvMY01EGKFtJo1YzNC8oUE6VZo",
          authDomain: "golden-paw-database.firebaseapp.com",
          projectId: "golden-paw-database",
          storageBucket: "golden-paw-database.firebasestorage.app",
          messagingSenderId: "163858364889",
          appId: "1:163858364889:web:12db63a67659cd094a01c8",
          measurementId: "G-H0R68LWSK6",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // Push Notifications setup
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _setupFCMToken(messaging);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Messaging setup failed: $e');
      }
    }
  }

  static Future<void> requestPushPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _setupFCMToken(messaging);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request push permissions: $e');
      }
    }
  }

  static Future<void> _setupFCMToken(FirebaseMessaging messaging) async {
    try {
      String? token = await messaging.getToken(
        vapidKey:
            "BNNSLNFl4zpOEubsCdhqQC2b5jTkpKV_qLoe6QtKM-fGQ6wqJ06pGhN2snwodgDKgrbF9rhelYMe2sV6mIxwdeU",
      );
      if (token != null) {
        print("FCM Token: $token");
        
        // We need to save this to the user doc when they log in.
        // We'll hook into Auth state changes so we are guaranteed to have a valid user.
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'fcm_token': token,
            }, SetOptions(merge: true));

            // Subscribe to promo updates via backend
            try {
              final tokenStr = await user.getIdToken();
              await http.post(
                Uri.parse('https://golden-paw-vault.onrender.com/subscribe-promo-topic'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $tokenStr',
                },
                body: jsonEncode({'token': token}),
              );
            } catch (e) {
              print("Failed to subscribe to topic: $e");
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
    }
  }
}

Future<Map<String, String>> getAuthHeaders() async {
  final headers = {'Content-Type': 'application/json'};
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final token = await user.getIdToken();
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
