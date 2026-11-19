import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../api_constants.dart';
import '../../src/firebase_service.dart';

/// Reasons a player can pick when reporting a post or comment. These must
/// match REPORT_REASONS in backend/src/routes/dogbookRoutes.js.
const List<String> kDogbookReportReasons = [
  'Not a dog',
  'Rude or abusive',
  'Spam',
  'Something else',
];

/// The result of a Book Of Dog request: [ok] and either [data] or [error].
class DogbookResult {
  final bool ok;
  final String error;
  final Map<String, dynamic> data;

  const DogbookResult(this.ok, {this.error = '', this.data = const {}});
}

/// Calls the moderated Book Of Dog backend. Reads come straight from
/// Firestore; every change goes through here.
class DogbookApi {
  static String get _base => '${ApiConstants.baseUrl}/dogbook';

  static DogbookResult _parse(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    if (response.statusCode == 200 && body['success'] == true) {
      return DogbookResult(true, data: body);
    }
    return DogbookResult(false,
        error: (body['error'] ?? 'Something went wrong. Please try again.').toString());
  }

  static Future<DogbookResult> _send(Future<http.Response> Function(Map<String, String>) call) async {
    try {
      return _parse(await call(await getAuthHeaders()));
    } catch (_) {
      return const DogbookResult(false,
          error: 'Could not reach Golden Paw. Check your connection and try again.');
    }
  }

  static Future<DogbookResult> sharePost({
    required Uint8List photo,
    required String fileName,
    required String dogName,
    required String caption,
  }) async {
    try {
      final headers = await getAuthHeaders();
      headers.remove('Content-Type');
      final request = http.MultipartRequest('POST', Uri.parse('$_base/posts'))
        ..headers.addAll(headers)
        ..fields['dog_name'] = dogName
        ..fields['caption'] = caption
        ..files.add(http.MultipartFile.fromBytes('photo', photo, filename: fileName));
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      return _parse(await http.Response.fromStream(streamed));
    } catch (_) {
      return const DogbookResult(false,
          error: 'Could not upload your photo. Check your connection and try again.');
    }
  }

  static Future<DogbookResult> deletePost(String id) =>
      _send((h) => http.delete(Uri.parse('$_base/posts/$id'), headers: h));

  static Future<DogbookResult> toggleLike(String postId) =>
      _send((h) => http.post(Uri.parse('$_base/posts/$postId/like'), headers: h));

  static Future<DogbookResult> addComment(String postId, String text) => _send((h) => http.post(
        Uri.parse('$_base/posts/$postId/comments'),
        headers: h,
        body: jsonEncode({'text': text}),
      ));

  static Future<DogbookResult> deleteComment(String id) =>
      _send((h) => http.delete(Uri.parse('$_base/comments/$id'), headers: h));

  static Future<DogbookResult> report(String type, String id, String reason) => _send((h) => http.post(
        Uri.parse('$_base/report'),
        headers: h,
        body: jsonEncode({'type': type, 'id': id, 'reason': reason}),
      ));

  static Future<DogbookResult> setBlocked(String uid, bool blocked) => _send((h) => http.post(
        Uri.parse('$_base/block'),
        headers: h,
        body: jsonEncode({'uid': uid, 'blocked': blocked}),
      ));

  static Future<DogbookResult> listReports({bool handled = false}) => _send((h) => http.get(
        Uri.parse('$_base/reports${handled ? '?status=handled' : ''}'),
        headers: h,
      ));

  static Future<DogbookResult> resolveReport(String targetKey, String action) => _send((h) => http.post(
        Uri.parse('$_base/reports/resolve'),
        headers: h,
        body: jsonEncode({'target_key': targetKey, 'action': action}),
      ));
}
