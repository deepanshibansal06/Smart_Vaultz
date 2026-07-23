import 'dart:convert';

import 'api_service.dart';

class UserService {
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await ApiService.get('/users/me', token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to load profile');
    }
    final m = _tryDecode(res.body);
    return m is Map<String, dynamic> ? m : <String, dynamic>{};
  }

  static Future<void> setMpin(String token, String pin) async {
    final res = await ApiService.post(
      '/users/me/mpin',
      {'pin': pin},
      token: token,
    );
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to set MPIN');
    }
  }

  static Future<bool> verifyMpin(String token, String pin) async {
    final res = await ApiService.post(
      '/users/me/mpin/verify',
      {'pin': pin},
      token: token,
    );
    final d = _tryDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(d?['message']?.toString() ?? 'Verification failed');
    }
    return d?['valid'] == true;
  }

  static Future<Map<String, dynamic>> updateProfile(
    String token, {
    String? name,
    String? phone,
    String? address,
    String? location,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    if (location != null) body['location'] = location;
    final res = await ApiService.put('/users/me', body, token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Update failed');
    }
    final m = _tryDecode(res.body);
    return m is Map<String, dynamic> ? m : <String, dynamic>{};
  }

  static Future<double> getWalletBalance(String token) async {
    final res = await ApiService.get('/users/me/wallet', token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to load balance');
    }
    final m = _tryDecode(res.body);
    if (m is! Map<String, dynamic>) return 0;
    final b = m['balance'];
    return (b is num) ? b.toDouble() : 0;
  }

  static Future<double> addWalletMoney(String token, double amount) async {
    final res = await ApiService.post(
      '/users/me/wallet/add',
      {'amount': amount},
      token: token,
    );
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to add money');
    }
    final m = _tryDecode(res.body);
    if (m is! Map<String, dynamic>) return 0;
    final b = m['balance'];
    return (b is num) ? b.toDouble() : 0;
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
