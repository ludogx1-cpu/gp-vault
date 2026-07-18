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
  String _statusMessage = "";
  bool _isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      bool isSupported = await FirebaseMessaging.instance.isSupported();
      if (!isSupported) {
        setState(() {
          _isVisible = true;
          _statusMessage = "Push notifications are not supported by this browser. (If on iPhone, you must be on iOS 16.4+ and open the app from your Home Screen).";
          _isButtonEnabled = false;
        });
        return;
      }

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.getNotificationSettings();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // If authorized, hide it entirely as requested
        setState(() {
          _isVisible = false;
        });
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        setState(() {
          _isVisible = true;
          _statusMessage = "Notifications are blocked by your browser settings. Please allow them in your browser preferences.";
          _isButtonEnabled = false;
        });
      } else {
        // notDetermined
        setState(() {
          _isVisible = true;
          _statusMessage = "Enable notifications to keep your streak alive.";
          _isButtonEnabled = true;
        });
      }
    } catch (e) {
      setState(() {
        _isVisible = true;
        _statusMessage = "Error checking notifications: $e";
        _isButtonEnabled = false;
      });
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
    _checkPermissions(); // Re-check to update UI state
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
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 14, 
              color: _isButtonEnabled ? null : Colors.redAccent,
              fontWeight: _isButtonEnabled ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _isButtonEnabled ? _requestPermissions : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _isButtonEnabled ? "Enable Notifications" : "Unavailable",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
