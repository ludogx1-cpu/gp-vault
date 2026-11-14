import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';
import 'firebase_service.dart';

/// Result of trying to use a referral code.
class ReferralResult {
  final bool ok;
  final String message;
  const ReferralResult(this.ok, this.message);
}

/// Invite links look like goldenpaw.dog/?ref=XXXXXXXX. The code is remembered
/// on this device until the visitor signs in, then sent to the server, which
/// links the new account to the person who invited them.
class ReferralService {
  static const _pendingKey = 'pending_referral_code';
  static final _codePattern = RegExp(r'^[A-Za-z0-9]{6,40}$');
  static StreamSubscription<User?>? _authSub;

  static String inviteLink(String uid) => 'https://goldenpaw.dog/?ref=${uid.substring(0, 8)}';

  /// Call once at start-up.
  static Future<void> init() async {
    if (kIsWeb) {
      final code = Uri.base.queryParameters['ref'];
      if (code != null && _codePattern.hasMatch(code)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_pendingKey, code);
        } catch (_) {}
      }
    }
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) unawaited(_sendPending());
    });
  }

  static Future<void> _sendPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_pendingKey);
      if (code == null) return;
      final result = await claim(code);
      // Keep the code only if the server couldn't be reached.
      if (result.ok || result.message != _offlineMessage) {
        await prefs.remove(_pendingKey);
      }
    } catch (_) {}
  }

  static const _offlineMessage = 'Could not reach the server. Please try again.';

  /// Links the signed-in account to the owner of [code].
  static Future<ReferralResult> claim(String code) async {
    final trimmed = code.trim();
    if (!_codePattern.hasMatch(trimmed)) {
      return const ReferralResult(false, 'That referral code is not valid.');
    }
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/referral/claim'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'code': trimmed}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return ReferralResult(data['linked'] == true, (data['message'] ?? '').toString());
      }
      return ReferralResult(false, (data['error'] ?? 'Could not use that code.').toString());
    } catch (_) {
      return const ReferralResult(false, _offlineMessage);
    }
  }

  /// The signed-in user's invited friends and earnings.
  static Future<Map<String, dynamic>?> stats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/referral/stats'),
        headers: await getAuthHeaders(),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
