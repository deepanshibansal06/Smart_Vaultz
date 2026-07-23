import 'dart:convert';

import 'api_service.dart';
import '../models/vault_model.dart';

class BookingItem {
  final String id;
  final String lockStatus; // 'open' | 'closed'
  final VaultModel vault;

  BookingItem({required this.id, required this.lockStatus, required this.vault});
}

class LockActionResult {
  final bool hasHardware;

  LockActionResult({required this.hasHardware});
}

class BookingService {
  static Future<List<BookingItem>> getMyBookings(String token) async {
    final res = await ApiService.get('/bookings/me', token: token);
    if (res.statusCode != 200) throw Exception('Failed to load bookings');
    List<dynamic> list;
    try {
      final decoded = jsonDecode(res.body);
      list = decoded is List<dynamic> ? decoded : [];
    } catch (_) {
      list = [];
    }
    return list.map((e) {
      final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
      final v = m['vault'];
      return BookingItem(
        id: m['_id']?.toString() ?? '',
        lockStatus: m['lockStatus']?.toString() ?? 'closed',
        vault: _vaultFromJson(v is Map<String, dynamic> ? v : <String, dynamic>{}),
      );
    }).toList();
  }

  static Future<BookingItem> createBooking(String token, String vaultId, {String paymentMethod = 'upi'}) async {
    final start = DateTime.now().toIso8601String();
    final end = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    final res = await ApiService.post(
      '/bookings',
      {'vaultId': vaultId, 'start': start, 'end': end, 'paymentMethod': paymentMethod},
      token: token,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Booking failed');
    }
    final m = _tryDecode(res.body) ?? {};
    final v = m['vault'];
    return BookingItem(
      id: m['_id']?.toString() ?? '',
      lockStatus: m['lockStatus']?.toString() ?? 'closed',
      vault: _vaultFromJson(v is Map<String, dynamic> ? v : <String, dynamic>{}),
    );
  }

  /// Returns [LockActionResult] with [hasHardware] true only for the locker with ESP (Locker 1).
  static Future<LockActionResult> openVault(String token, String bookingId) async {
    final res = await ApiService.post('/bookings/open/$bookingId', {}, token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to open');
    }
    final d = _tryDecode(res.body) ?? {};
    return LockActionResult(hasHardware: d['hasHardware'] == true);
  }

  static Future<LockActionResult> closeVault(String token, String bookingId) async {
    final res = await ApiService.post('/bookings/close/$bookingId', {}, token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to close');
    }
    final d = _tryDecode(res.body) ?? {};
    return LockActionResult(hasHardware: d['hasHardware'] == true);
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

  static VaultModel _vaultFromJson(Map<String, dynamic> j) {
    return VaultModel(
      id: j['_id']?.toString() ?? '',
      lockerNo: j['lockerNo']?.toString() ?? '',
      location: j['location']?.toString() ?? '',
      price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0,
      slotDate: j['slotDate']?.toString() ?? '',
      timeSlot: j['timeSlot']?.toString() ?? '',
      status: j['status']?.toString() ?? 'booked',
    );
  }
}
