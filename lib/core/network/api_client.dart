import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    String? baseUrl,
    http.Client? httpClient,
  })  : _tokenStore = tokenStore,
        _baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
        _http = httpClient ?? http.Client();

  final TokenStore _tokenStore;
  final String _baseUrl;
  final http.Client _http;

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$normalized').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Map<String, String> _headers({bool auth = false, bool jsonBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth) {
      final token = _tokenStore.accessToken;
      if (token == null || token.isEmpty) {
        throw ApiException('Not signed in', statusCode: 401, code: 'unauthorized');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final res = await _http.get(
      _uri(path, query),
      headers: _headers(auth: auth),
    );
    return _decode(res);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = false,
    Map<String, String>? headers,
  }) async {
    final res = await _http.post(
      _uri(path),
      headers: {
        ..._headers(auth: auth, jsonBody: body != null),
        ...?headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final res = await _http.put(
      _uri(path),
      headers: _headers(auth: auth, jsonBody: body != null),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    final res = await _http.patch(
      _uri(path),
      headers: _headers(auth: auth, jsonBody: body != null),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(
    String path, {
    bool auth = false,
  }) async {
    final res = await _http.delete(
      _uri(path),
      headers: _headers(auth: auth),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final raw = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return raw;
    }
    String message = 'Request failed (${res.statusCode})';
    String? code;
    if (raw is Map<String, dynamic>) {
      message = (raw['message'] as String?) ?? message;
      code = raw['error'] as String?;
    }
    throw ApiException(message, statusCode: res.statusCode, code: code);
  }
}
