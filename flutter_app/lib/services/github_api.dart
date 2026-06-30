import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Talks to the backend's /api/projects/:id/github/* endpoints.
/// The backend holds the GitHub token server-side; this client never
/// sees or stores it.
class GithubApi {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, dynamic>> connect(int projectId, String repoUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/github/connect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'repoUrl': repoUrl}),
    );
    return _decode(res);
  }

  /// Returns the zip download URL; opening it (e.g. via url_launcher)
  /// lets the browser handle the download/save.
  static String pullUrl(int projectId) => '$baseUrl/projects/$projectId/github/pull';
  static String treeUrl(int projectId) => '$baseUrl/projects/$projectId/github/tree';

  static Future<List<Map<String, dynamic>>> repoFiles(int projectId) async {
    final res = await http.get(Uri.parse(treeUrl(projectId)));
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body['message'] ?? 'GitHub request failed (${res.statusCode})');
    }
    return List<Map<String, dynamic>>.from(body['files'] as List);
  }

  static Future<String> fetchFile(int projectId, String path) async {
    final url = '$baseUrl/projects/$projectId/github/file?path=${Uri.encodeComponent(path)}';
    final res = await http.get(Uri.parse(url));
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body['message'] ?? 'GitHub request failed (${res.statusCode})');
    }
    return body['content'] as String? ?? '';
  }

  static Future<Map<String, dynamic>> push(
    int projectId, {
    required Uint8List zipBytes,
    required String fileName,
    String? message,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/projects/$projectId/github/push'),
    );
    if (message != null && message.isNotEmpty) {
      request.fields['message'] = message;
    }
    request.files.add(
      http.MultipartFile.fromBytes('zip', zipBytes, filename: fileName),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body['message'] ?? 'GitHub request failed (${res.statusCode})');
    }
    return body;
  }
}
