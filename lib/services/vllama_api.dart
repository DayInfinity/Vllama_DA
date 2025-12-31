import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'app_log.dart';

class VllamaApi {
  static const String baseUrl = 'http://localhost:5000';

  static Future<Map<String, dynamic>> generate3d({
    required File imageFile,
    required String username,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate/3d');
    AppLog.add('API POST $uri (multipart fields: image, username, apiKey)');
    AppLog.add('Image path: ${imageFile.path}');
    AppLog.add('Image bytes: ${await imageFile.length()}');
    final request = http.MultipartRequest('POST', uri);

    request.fields['username'] = username;
    request.fields['apiKey'] = apiKey;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    AppLog.add('API status: ${response.statusCode}');
    AppLog.add('API response bytes: ${response.bodyBytes.length}');

    Map<String, dynamic> jsonBody;
    try {
      final decoded = json.decode(response.body);
      jsonBody = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw Exception(
        'Server returned invalid JSON (${response.statusCode}). Body: ${response.body}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      AppLog.add('API ok. Keys: ${jsonBody.keys.toList()}');
      return jsonBody;
    }

    final message = (jsonBody['error'] ?? jsonBody['message'] ?? 'Unknown error').toString();
    throw Exception('API Error (${response.statusCode}): $message');
  }
}


