import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../main.dart';

class FirebaseService {
  static Future<void> initialize() async {
    if (kIsWeb || (!kIsWeb && Platform.isWindows)) {
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

    // Initialize Firebase App Check
    // - Android: Play Integrity (production) or Debug provider (debug builds)
    // - Web: reCAPTCHA Enterprise
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
      providerApple: AppleAppAttestProvider(),
      providerWeb: ReCaptchaEnterpriseProvider(
        '6LeEKjotAAAAABBcMyZho_GL7pH7HW7YlQ_JowPy',
      ),
    );

    // Initialize Performance Monitoring
    FirebasePerformance.instance;

    // Push Notifications setup
    try {
      bool isSupported = await FirebaseMessaging.instance.isSupported();
      if (isSupported) {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging.getNotificationSettings();

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _setupFCMToken(messaging);
        }

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            final title = message.notification?.title ?? 'Notification';
            final body = message.notification?.body ?? '';
            
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (body.isNotEmpty) Text(body),
                  ],
                ),
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Messaging setup failed: $e');
      }
    }
  }

  static Future<void> requestPushPermissions() async {
    try {
      bool isSupported = await FirebaseMessaging.instance.isSupported();
      if (!isSupported) return;

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
        debugPrint('Failed to request push permissions: $e');
      }
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to request push permissions: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)),
      );
    }
  }

  static Future<void> _setupFCMToken(FirebaseMessaging messaging) async {
    try {
      // NOTE: This VAPID key is a public identifier used to verify the sender 
      // of push notifications to the browser. It is NOT a secret credential 
      // and is safe to be included in client-side code.
      String? token = await messaging.getToken(
        vapidKey:
            "BNNSLNFl4zpOEubsCdhqQC2b5jTkpKV_qLoe6QtKM-fGQ6wqJ06pGhN2snwodgDKgrbF9rhelYMe2sV6mIxwdeU",
      );
      if (token != null) {
        debugPrint("FCM Token: $token");
        
        // Handle already logged-in user
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _registerTokenForUser(token, currentUser);
        }

        // We need to save this to the user doc when they log in.
        // We'll hook into Auth state changes so we are guaranteed to have a valid user.
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            _registerTokenForUser(token, user);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get FCM token: $e');
      }
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to get FCM token: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)),
      );
    }
  }

  static Future<void> _registerTokenForUser(String token, User user) async {
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcm_token': token,
    }, SetOptions(merge: true));

    // Subscribe to promo and pet updates via backend
    try {
      final tokenStr = await user.getIdToken();
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/subscribe-promo-topic'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenStr',
        },
        body: jsonEncode({'token': token}),
      );
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/subscribe-pet-topic'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenStr',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      debugPrint("Failed to subscribe to topics: $e");
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to subscribe to topics: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 10)),
      );
    }
  }
  static Future<void> disablePushPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken(
        vapidKey: "BNNSLNFl4zpOEubsCdhqQC2b5jTkpKV_qLoe6QtKM-fGQ6wqJ06pGhN2snwodgDKgrbF9rhelYMe2sV6mIxwdeU",
      );
      
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && token != null) {
        // Unsubscribe from topics
        final tokenStr = await currentUser.getIdToken();
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/unsubscribe-promo-topic'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $tokenStr'},
          body: jsonEncode({'token': token}),
        );
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/unsubscribe-pet-topic'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $tokenStr'},
          body: jsonEncode({'token': token}),
        );

        // Remove from firestore
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'fcm_token': FieldValue.delete(),
        });
      }

      // Delete token from device
      await messaging.deleteToken();
      
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Notifications disabled successfully.'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to disable push permissions: $e');
      }
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to disable notifications: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
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
