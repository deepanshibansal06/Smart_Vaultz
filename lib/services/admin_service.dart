import 'dart:convert';

import 'api_service.dart';

class AdminService {
  static Future<Map<String, int>> getDashboardStats(String token) async {
    final res = await ApiService.get('/admin/dashboard', token: token);
    if (res.statusCode != 200) throw Exception('Failed to load dashboard');
    final data = jsonDecode(res.body) as Map<String, dynamic>? ?? {};
    return {
      'totalVaults': (data['totalVaults'] as num?)?.toInt() ?? 0,
      'totalBookings': (data['totalBookings'] as num?)?.toInt() ?? 0,
      'totalUsers': (data['totalUsers'] as num?)?.toInt() ?? 0,
    };
  }
}
