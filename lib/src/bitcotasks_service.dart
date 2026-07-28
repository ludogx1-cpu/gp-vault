import 'dart:convert';
import 'package:http/http.dart' as http;

class BitcoTasksService {
  static const String baseUrl = 'https://bitcotasks.com';
  static const String gateway = '/offerwall';
  
  // From the user's existing iframe URL
  static const String apiKey = '6xwmdur28o2s2jx3y4nj4ldt6jx5u9';

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> bodyParams, String subId) async {
    final Map<String, String> finalParams = {
      'apiKey': apiKey,
      'subId': subId,
    };

    bodyParams.forEach((key, value) {
      finalParams[key] = value.toString();
    });

    final response = await http.post(
      Uri.parse('$baseUrl$gateway'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: finalParams,
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {};
    }
  }

  /// Fetches offers/surveys/tasks for a given category [type].
  /// [type] can be: 'surveys', 'offers', 'ptc', 'video', 'faucet', 'shortlinks', 'tasks', 'article'
  static Future<List<dynamic>> getOffers(String subId, String type) async {
    final Map<String, dynamic> params = {
      'action': 'switch_cat',
      'type': type,
    };
    
    // The JS SDK adds provider = 'bitcotasks' for surveys and offers
    if (type == 'surveys' || type == 'offers') {
      params['provider'] = 'bitcotasks';
    }

    final data = await _post(params, subId);
    
    if (data.containsKey('items')) {
      return data['items'] as List<dynamic>;
    } else if (data.containsKey('offers')) {
      return data['offers'] as List<dynamic>;
    }
    
    return [];
  }

  /// Returns the URL to open for a shortlink.
  static Future<String?> getShortlink(String subId, String id) async {
    final data = await _post({
      'action': 'getShortlink',
      'data': id,
    }, subId);
    
    return data['link'] as String?;
  }

  /// Initializes a PTC or Video transaction and returns the URL to open/embed.
  static Future<Map<String, dynamic>> initTransaction(String subId, String hash, String type) async {
    return await _post({
      'action': 'init_transaction',
      'hash': hash,
      'sid': subId,
      'key': apiKey,
      'type': type,
    }, subId);
  }

  /// Returns the faucet claim URL.
  static String getFaucetClaimUrl(String subId, String idOrHash) {
    // The JS SDK opens this URL directly for faucets
    return '$baseUrl/post/$apiKey/$subId/$idOrHash';
  }
}
