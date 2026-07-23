import 'dart:convert';

import '../core/error_utils.dart';
import 'api_service.dart';

String _connectionErrorHint(Object e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('failed host lookup') ||
      msg.contains('errno 111') ||
      msg.contains('111') ||
      msg.contains('timeout') ||
      msg.contains('timed out') ||
      msg.contains('socket') ||
      msg.contains('network') ||
      msg.contains('handshakeexception')) {
    return userFacingErrorMessage(e);
  }
  if (msg.contains('formatexception') || msg.contains('unexpected character')) {
    return 'Server returned invalid response. Please try again later.';
  }
  return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}

/// Safely decode JSON. Returns null if body is empty or invalid.
Map<String, dynamic>? _tryDecode(String body) {
  if (body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

class AuthService {
  /// Returns map with [token] and [role] on success. Throws on error.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
    final res = await ApiService.post("/auth/login", {
      "email": email,
      "password": password,
    });
    final data = _tryDecode(res.body);
    if (res.statusCode != 200) {
      final msg = data?['message'] ?? data?['error'] ?? data?['msg'] ?? 'Login failed';
      throw Exception(msg.toString());
    }
    final token = data?['token'] ?? data?['accessToken'] ?? '';
    final role = data?['role'] ?? data?['user']?['role'] ?? 'user';
    final userName = data?['name']?.toString();
    final userEmail = data?['email']?.toString();
    return {
      'token': token.toString(),
      'role': role.toString(),
      if (userName != null) 'name': userName,
      if (userEmail != null) 'email': userEmail,
    };
    } catch (e) {
      throw Exception(_connectionErrorHint(e));
    }
  }

  /// Completes signup. Pass [otp] when using signup-with-OTP flow. Throws on error.
  static Future<void> signup(String name, String email, String password, {String? otp}) async {
    try {
      final body = <String, dynamic>{"name": name, "email": email, "password": password};
      if (otp != null && otp.trim().isNotEmpty) body["otp"] = otp.trim();
      final res = await ApiService.post("/auth/signup", body);
      if (res.statusCode != 200 && res.statusCode != 201) {
        final data = _tryDecode(res.body);
        final msg = data?['message'] ?? data?['error'] ?? data?['msg'] ?? 'Signup failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      throw Exception(_connectionErrorHint(e));
    }
  }

  /// Sends OTP to [email]. [type] is 'forgot' or 'signup'.
  /// Returns map with [message] and optional [checkSpamNotice]. Throws on error.
  /// Uses a longer timeout (45s) because backend may cold-start (e.g. Render) and sending email can be slow.
  static Future<Map<String, String>> sendOtp(String email, String type) async {
    try {
      final res = await ApiService.post(
        "/auth/send-otp",
        {"email": email.trim(), "type": type},
        requestTimeout: const Duration(seconds: 45),
      );
      if (res.statusCode != 200) {
        final data = _tryDecode(res.body);
        final msg = data?['message'] ?? 'Failed to send OTP';
        throw Exception(msg.toString());
      }
      final data = _tryDecode(res.body) ?? {};
      return {
        'message': data['message']?.toString() ?? 'OTP sent to your email',
        if (data['checkSpamNotice'] != null) 'checkSpamNotice': data['checkSpamNotice']!.toString(),
      };
    } catch (e) {
      throw Exception(_connectionErrorHint(e));
    }
  }

  /// Resets password using OTP. Throws on error.
  static Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      final res = await ApiService.post("/auth/reset-password", {
        "email": email.trim(),
        "otp": otp.trim(),
        "newPassword": newPassword,
      });
      if (res.statusCode != 200) {
        final data = _tryDecode(res.body);
        final msg = data?['message'] ?? 'Reset failed';
        throw Exception(msg.toString());
      }
    } catch (e) {
      throw Exception(_connectionErrorHint(e));
    }
  }
}