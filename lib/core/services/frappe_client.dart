import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/frappe_config.dart';

class FrappeClient {
  FrappeClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _sessionCookieStorageKey = 'frappe_session_cookie';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  final http.Client _client;
  static String? _sessionCookie;
  static bool _sessionRestored = false;
  static Future<void>? _restoreFuture;

  Future<void> login(String email, String password) async {
    final response = await _postRaw(
      '/api/method/login',
      body: {'usr': email, 'pwd': password},
      useTokenAuth: false,
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    _sessionCookie = _extractSessionCookie(response);
    await _saveSessionCookie();
  }

  Future<void> logout() async {
    try {
      await post('/api/method/logout', useTokenAuth: false);
    } finally {
      _sessionCookie = null;
      await _saveSessionCookie();
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useTokenAuth = true,
  }) async {
    await _ensureSessionRestored();
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _client.get(
      uri,
      headers: _headers(useTokenAuth: useTokenAuth),
    );
    _ensureSuccess(response);
    return _decode(response.body);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool useTokenAuth = true,
  }) async {
    await _ensureSessionRestored();
    final response = await _postRaw(
      path,
      body: body,
      queryParameters: queryParameters,
      useTokenAuth: useTokenAuth,
    );
    _ensureSuccess(response);
    return response.body.isEmpty ? <String, dynamic>{} : _decode(response.body);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool useTokenAuth = true,
  }) async {
    await _ensureSessionRestored();
    final uri = _buildUri(path);
    final response = await _client.put(
      uri,
      headers: _headers(useTokenAuth: useTokenAuth),
      body: jsonEncode(body ?? {}),
    );
    _ensureSuccess(response);
    return _decode(response.body);
  }

  Future<Map<String, dynamic>> uploadFile({
    required File file,
    bool isPrivate = false,
    String? doctype,
    String? docname,
    String? fieldname,
  }) async {
    await _ensureSessionRestored();
    final uri = _buildUri('/api/method/upload_file');
    final request = http.MultipartRequest('POST', uri);
    final headers = _headers();
    headers.remove(HttpHeaders.contentTypeHeader);
    request.headers.addAll(headers);

    request.fields['is_private'] = isPrivate ? '0' : '0';
    if (doctype != null) request.fields['doctype'] = doctype;
    if (docname != null) request.fields['docname'] = docname;
    if (fieldname != null) request.fields['fieldname'] = fieldname;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await http.Response.fromStream(await request.send());
    _ensureSuccess(response);
    return _decode(response.body);
  }

  Future<http.Response> _postRaw(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool useTokenAuth = true,
  }) async {
    await _ensureSessionRestored();
    final uri = _buildUri(path, queryParameters: queryParameters);
    final response = await _client.post(
      uri,
      headers: _headers(useTokenAuth: useTokenAuth),
      body: jsonEncode(body ?? {}),
    );
    return response;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedBase = FrappeConfig.baseUrl.endsWith('/')
        ? FrappeConfig.baseUrl.substring(0, FrappeConfig.baseUrl.length - 1)
        : FrappeConfig.baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, String> _headers({bool useTokenAuth = true}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };

    // Use API key for app resource calls when enabled.
    if (useTokenAuth && FrappeConfig.useTokenAuth) {
      headers[HttpHeaders.authorizationHeader] =
          'token ${FrappeConfig.apiKey}:${FrappeConfig.apiSecret}';
      return headers;
    }

    // Otherwise use user session (auth/login/logout/current-user checks).
    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] = _sessionCookie!;
    }

    return headers;
  }

  Future<void> _ensureSessionRestored() {
    if (_sessionRestored) return Future.value();
    _restoreFuture ??= _restoreSessionFromStorage();
    return _restoreFuture!;
  }

  Future<void> _restoreSessionFromStorage() async {
    try {
      _sessionCookie = await _secureStorage.read(key: _sessionCookieStorageKey);
    } catch (_) {
      // Ignore secure storage errors and continue without persisted session.
    } finally {
      _sessionRestored = true;
    }
  }

  Future<void> _saveSessionCookie() async {
    try {
      if (_sessionCookie == null || _sessionCookie!.isEmpty) {
        await _secureStorage.delete(key: _sessionCookieStorageKey);
      } else {
        await _secureStorage.write(
          key: _sessionCookieStorageKey,
          value: _sessionCookie,
        );
      }
    } catch (_) {
      // Ignore secure storage errors to avoid blocking auth flow.
    }
  }

  // Map<String, String> _headers({bool useTokenAuth = true}) {
  //   final headers = <String, String>{
  //     HttpHeaders.contentTypeHeader: 'application/json',
  //     HttpHeaders.acceptHeader: 'application/json',
  //   };

  //   if (useTokenAuth && FrappeConfig.useTokenAuth) {
  //     headers[HttpHeaders.authorizationHeader] =
  //         'token ${FrappeConfig.apiKey}:${FrappeConfig.apiSecret}';
  //   }

  //   if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
  //     headers[HttpHeaders.cookieHeader] = _sessionCookie!;
  //   }

  //   return headers;
  // }

  String? _extractSessionCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return null;
    final cookieParts = setCookie.split(';');
    final sessionPart = cookieParts.firstWhere(
      (part) => part.trim().startsWith('sid='),
      orElse: () => '',
    );
    return sessionPart.isEmpty ? null : sessionPart.trim();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('Frappe request failed: ${response.statusCode}');
    }
    throw Exception('Frappe request failed: ${response.statusCode} - $body');
  }

  //   Map<String, dynamic> _decode(String body) {
  //     final decoded = jsonDecode(body);
  //     if (decoded is Map<String, dynamic>) {
  //       return decoded;
  //     }
  //     return <String, dynamic>{'message': decoded};
  //   }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map && decoded.containsKey('message')) {
        final message = decoded['message'];

        if (message is String) {
          try {
            // Convert Python dict to JSON
            String jsonStr = message
                .replaceAll("'", '"')
                .replaceAll("True", "true")
                .replaceAll("False", "false")
                .replaceAll("None", "null");

            return jsonDecode(jsonStr);
          } catch (e) {
            // If parsing fails, keep original message shape.
            return {'message': message};
          }
        } else if (message is Map) {
          // Message is already a map
          return Map<String, dynamic>.from(message);
        } else {
          // Message is other type (list, bool, etc)
          return {'message': message};
        }
      }

      // Return decoded as is
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{'data': decoded};
    } catch (e) {
      // If JSON decode fails entirely, return empty map
      print('JSON decode error: $e, body: $body');
      return <String, dynamic>{};
    }
  }
}
