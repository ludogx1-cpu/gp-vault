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

/// A photo picked on the device, ready to upload.
class PickedPhoto {
  final Uint8List bytes;
  final String name;

  const PickedPhoto(this.bytes, this.name);
}

/// The public link to a post, for sharing.
String dogbookPostUrl(String postId) => 'https://goldenpaw.dog/book-of-dog/post/$postId';

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

  /// Sends a form with optional photos (multipart).
  static Future<DogbookResult> _multipart(
    String method,
    String path,
    Map<String, String> fields, {
    List<PickedPhoto> photos = const [],
    String fileField = 'photos',
  }) async {
    try {
      final headers = await getAuthHeaders();
      headers.remove('Content-Type');
      final request = http.MultipartRequest(method, Uri.parse('$_base$path'))
        ..headers.addAll(headers)
        ..fields.addAll(fields);
      for (final p in photos) {
        request.files.add(http.MultipartFile.fromBytes(fileField, p.bytes, filename: p.name));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 120));
      return _parse(await http.Response.fromStream(streamed));
    } catch (_) {
      return const DogbookResult(false,
          error: 'Could not upload. Check your connection and try again.');
    }
  }

  /// A new post from one of your dogs: text, up to 4 photos, or both.
  static Future<DogbookResult> createPost({
    required String dogId,
    required String text,
    List<PickedPhoto> photos = const [],
  }) =>
      _multipart('POST', '/posts', {'dog_id': dogId, 'text': text}, photos: photos);

  static Future<DogbookResult> editPost(String id, String text) => _send((h) => http.patch(
        Uri.parse('$_base/posts/$id'),
        headers: h,
        body: jsonEncode({'text': text}),
      ));

  static Future<DogbookResult> resharePost(String id, String dogId, String text) => _send((h) => http.post(
        Uri.parse('$_base/posts/$id/reshare'),
        headers: h,
        body: jsonEncode({'dog_id': dogId, 'text': text}),
      ));

  static Future<DogbookResult> countShare(String id) =>
      _send((h) => http.post(Uri.parse('$_base/posts/$id/shared'), headers: h));

  static Future<DogbookResult> createDog(Map<String, String> fields, {PickedPhoto? photo}) =>
      _multipart('POST', '/dogs', fields, photos: [?photo], fileField: 'photo');

  static Future<DogbookResult> updateDog(String id, Map<String, String> fields, {PickedPhoto? photo}) =>
      _multipart('PATCH', '/dogs/$id', fields, photos: [?photo], fileField: 'photo');

  static Future<DogbookResult> deleteDog(String id) =>
      _send((h) => http.delete(Uri.parse('$_base/dogs/$id'), headers: h));

  static Future<DogbookResult> toggleFollow(String dogId) =>
      _send((h) => http.post(Uri.parse('$_base/dogs/$dogId/follow'), headers: h));

  static Future<DogbookResult> toggleCommentLike(String commentId) =>
      _send((h) => http.post(Uri.parse('$_base/comments/$commentId/like'), headers: h));

  static Future<DogbookResult> markNotificationsRead() =>
      _send((h) => http.post(Uri.parse('$_base/notifications/read'), headers: h));

  static Future<DogbookResult> deletePost(String id) =>
      _send((h) => http.delete(Uri.parse('$_base/posts/$id'), headers: h));

  static Future<DogbookResult> toggleLike(String postId) =>
      _send((h) => http.post(Uri.parse('$_base/posts/$postId/like'), headers: h));

  static Future<DogbookResult> addComment(String postId, String text, {String? parentId, String? dogId}) =>
      _send((h) => http.post(
            Uri.parse('$_base/posts/$postId/comments'),
            headers: h,
            body: jsonEncode({
              'text': text,
              'parent_id': ?parentId,
              'dog_id': ?dogId,
            }),
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
