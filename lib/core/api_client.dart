import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required String baseUrl})
      : _baseUri = Uri.parse(baseUrl),
        _client = http.Client();

  final Uri _baseUri;
  final http.Client _client;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> get(String path) async {
    final response = await _send('GET', path);
    return _decode(response.body);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _send('POST', path, body: body);
    return _decode(response.body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _resolve(path);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    late http.Response response;

    if (method == 'GET') {
      response = await _client.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    } else {
      throw UnsupportedError('Metodo HTTP no soportado: $method');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'La API respondio con estado ${response.statusCode}.',
        response.body,
      );
    }

    return response;
  }

  Uri _resolve(String path) {
    final cleanPath = path.startsWith('/')
        ? path.substring(1)
        : path;

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