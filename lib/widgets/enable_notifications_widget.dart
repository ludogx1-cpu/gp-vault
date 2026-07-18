import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../src/firebase_service.dart';

class EnableNotificationsWidget extends StatefulWidget {
  const EnableNotificationsWidget({super.key});

  @override
  State<EnableNotificationsWidget> createState() => _EnableNotificationsWidgetState();
}

class _EnableNotificationsWidgetState extends State<EnableNotificationsWidget> {
  bool _isVisible = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.getNotificationSettings();
      
      // If the user hasn't been asked yet, show the button.
      // If they authorized or denied, we hide the button forever.
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        setState(() {
          _isVisible = true;
        });
      }
    } catch (e) {
      // Ignore errors (e.g., unsupported platform) and keep it hidden.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    await FirebaseService.requestPushPermissions();
    // After requesting, hide the button regardless of outcome (accept or reject)
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.notifications_active, color: Colors.blueAccent, size: 40),
          const SizedBox(height: 10),
          const Text(
            "Never miss your faucet claims!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          const Text(
            "Enable notifications to keep your streak alive.",
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _requestPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "Enable Notifications",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
