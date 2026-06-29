import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class FirebaseService {
  static Future<void> initialize() async {
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

    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider('6LeEKjotAAAAABBcMyZho_GL7pH7HW7YlQ_JowPy'),
    );
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
