import 'dart:convert';
import 'dart:io';

class ApiClient {
  ApiClient({required String baseUrl}) : _baseUri = Uri.parse(baseUrl);

  final Uri _baseUri;
  final HttpClient _client = HttpClient();

  Future<dynamic> get(String path) async {
    final response = await _send('GET', path);
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _send('POST', path, body: body);
    return _decode(response);
  }

  Future<String> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _client.openUrl(method, _resolve(path));
    request.headers.contentType = ContentType.json;

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'La API respondio con estado ${response.statusCode}.',
        responseBody,
      );
    }

    return responseBody;
  }

  Uri _resolve(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.replace(
      path: [
        if (_baseUri.path.isNotEmpty)
          _baseUri.path.replaceFirst(RegExp(r'/$'), ''),
        cleanPath,
      ].where((segment) => segment.isNotEmpty).join('/'),
    );
  }

  dynamic _decode(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    return jsonDecode(responseBody);
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.body);

  final String message;
  final String body;

  @override
  String toString() => '$message $body';
}
