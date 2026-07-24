import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../src/firebase_service.dart';
import '../src/theme_provider.dart';

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
  bool _isAuthorized = false;

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
          _statusMessage = "Push notifications are not supported on your current browser/device. iOS users must first 'Install App to Device' to receive notifications.";
          _isButtonEnabled = false;
        });
        return;
      }

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.getNotificationSettings();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        setState(() {
          _isVisible = true;
          _statusMessage = "Notifications are enabled! You're all set.";
          _isButtonEnabled = false;
          _isAuthorized = true;
        });
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        setState(() {
          _isVisible = true;
          _statusMessage = "You have blocked notifications for this site. To enable them, please reset your browser site settings.";
          _isButtonEnabled = false;
          _isAuthorized = false;
        });
      } else {
        // notDetermined
        setState(() {
          _isVisible = true;
          _statusMessage = "Get instant alerts for daily promo codes & pet care reminders!";
          _isButtonEnabled = true;
          _isAuthorized = false;
        });
      }
    } catch (e) {
      setState(() {
        _isVisible = true;
        _statusMessage = "Error checking notification status: $e";
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

  Future<void> _disablePermissions() async {
    await FirebaseService.disablePushPermissions();
    setState(() {
      _statusMessage = "Notifications have been disabled.";
      _isAuthorized = false;
      _isButtonEnabled = true; // allow them to re-request if browser still allows it
    });
    // Re-check to see if browser still reports as authorized
    // If it does, _checkPermissions will set it back to enabled. 
    // Wait, if we disable, we delete the token. But the browser is still "authorized".
    // If they click enable again, it will just get a new token.
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_isVisible) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.notifications_active, color: Colors.blueAccent, size: 40),
              const SizedBox(height: 10),
              Text(
            "Never miss your faucet claims!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 14, 
              color: _isButtonEnabled ? (isDark ? Colors.white70 : Colors.black87) : Colors.redAccent,
              fontWeight: _isButtonEnabled ? FontWeight.normal : FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Note: You can only turn notifications on or off if you have installed the Golden Paw App.",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          if (_isAuthorized)
            ElevatedButton(
              onPressed: _disablePermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Turn off notifications",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          else
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
      },
    );
  }
}
