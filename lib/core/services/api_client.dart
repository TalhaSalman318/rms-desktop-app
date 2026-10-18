import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? client,
    SessionTokenStorage? tokenStorage,
  }) : baseUrl =
           baseUrl ??
           const String.fromEnvironment(
             'API_BASE_URL',
             defaultValue: 'http://localhost:5000/api',
           ),
       _client = client ?? http.Client(),
       _tokenStorage = tokenStorage ?? SessionTokenStorage();

  final String baseUrl;
  final http.Client _client;
  final SessionTokenStorage _tokenStorage;
  String? _sessionToken;
  void Function()? onUnauthorized;

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final localHosts = {'localhost', '127.0.0.1', '::1'};
    if (uri.scheme != 'https' && !localHosts.contains(uri.host.toLowerCase())) {
      throw const ApiException(
        'HTTPS is required when connecting to a non-local backend.',
      );
    }
    final headers = {
      'Content-Type': 'application/json',
      if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
    };
    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encoded);
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 &&
          path != '/auth/login' &&
          path != '/auth/logout') {
        _sessionToken = null;
        onUnauthorized?.call();
        await _tokenStorage.delete();
      }
      throw ApiException(
        decoded['message']?.toString() ?? 'Request failed',
        response.statusCode,
      );
    }
    return decoded['data'] ?? decoded;
  }

  Future<List<Map<String, Object?>>> list(
    String resource, {
    Map<String, String>? query,
  }) async {
    final data = await request('GET', '/$resource', query: query);
    return (data as List)
        .cast<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  Future<Map<String, Object?>> get(String resource, int id) async =>
      Map<String, Object?>.from(await request('GET', '/$resource/$id'));

  Future<Map<String, Object?>> save(
    String resource,
    Map<String, dynamic> values, {
    int? id,
  }) async => Map<String, Object?>.from(
    await request(
      id == null ? 'POST' : 'PUT',
      id == null ? '/$resource' : '/$resource/$id',
      body: values,
    ),
  );

  Future<void> remove(String resource, int id) async {
    await request('DELETE', '/$resource/$id');
  }

  Future<Map<String, Object?>> authenticate(
    String username,
    String password,
  ) async {
    final result = Map<String, Object?>.from(
      await request(
        'POST',
        '/auth/login',
        body: {'username': username, 'password': password},
      ),
    );
    final token = result['token'];
    final admin = result['admin'];
    if (token is! String || token.isEmpty || admin is! Map) {
      throw const ApiException(
        'The backend returned an invalid login response.',
      );
    }
    _sessionToken = token;
    try {
      await _tokenStorage.write(token);
    } catch (_) {
      try {
        await request('POST', '/auth/logout');
      } finally {
        _sessionToken = null;
      }
      rethrow;
    }
    return Map<String, Object?>.from(admin);
  }

  Future<Map<String, Object?>?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;
    _sessionToken = token;
    try {
      return Map<String, Object?>.from(await request('GET', '/auth/me'));
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await clearPersistedSession();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (_sessionToken != null) await request('POST', '/auth/logout');
    } finally {
      await clearPersistedSession();
    }
  }

  Future<void> clearPersistedSession() async {
    _sessionToken = null;
    await _tokenStorage.delete();
  }

  Future<Map<String, Object?>> changePassword(
    String currentPassword,
    String newPassword,
  ) async => Map<String, Object?>.from(
    await request(
      'PUT',
      '/auth/password',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    ),
  );

  Future<int> nextOrderNumber() async =>
      (await request('GET', '/orders/next-number') as Map)['next_number']
          as int;

  Future<Map<String, Object?>> placeOrder(Map<String, dynamic> values) async =>
      Map<String, Object?>.from(await request('POST', '/orders', body: values));

  Future<List<Map<String, Object?>>> analytics(
    String resource,
    Map<String, String> query,
  ) async {
    final data = await request('GET', '/$resource', query: query);
    return (data as List)
        .cast<Map>()
        .map((row) => Map<String, Object?>.from(row))
        .toList();
  }

  Future<Map<String, Object?>> analyticsMap(
    String resource,
    Map<String, String> query,
  ) async => Map<String, Object?>.from(
    await request('GET', '/analytics/$resource', query: query),
  );
}
