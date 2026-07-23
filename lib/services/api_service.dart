import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';
import '../core/env_io.dart' if (dart.library.html) '../core/env_stub.dart' as env_platform;

class ApiService {
  static const Duration timeout = Duration(seconds: 15);

  static String get _baseUrl => env_platform.resolveBaseUrl(Env.baseUrl);
  /// Base URL used for requests (for error messages).
  static String get baseUrl => _baseUrl;

  static Future<http.Response> get(String endpoint, {String? token}) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return http
        .get(Uri.parse('$_baseUrl$endpoint'), headers: headers.isEmpty ? null : headers)
        .timeout(timeout, onTimeout: () => throw TimeoutException('Request timed out'));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token, Duration? requestTimeout}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    final t = requestTimeout ?? timeout;
    return http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(t, onTimeout: () => throw TimeoutException('Request timed out'));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return http
        .put(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(timeout, onTimeout: () => throw TimeoutException('Request timed out'));
  }

  static Future<http.Response> delete(String endpoint, {String? token}) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return http
        .delete(Uri.parse('$_baseUrl$endpoint'), headers: headers.isEmpty ? null : headers)
        .timeout(timeout, onTimeout: () => throw TimeoutException('Request timed out'));
  }
}