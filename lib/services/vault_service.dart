import 'dart:convert';

import 'api_service.dart';
import '../models/vault_model.dart';

class VaultService {
  static Future<List<VaultModel>> getVaults(String token, {bool availableOnly = false}) async {
    final path = availableOnly ? '/vaults?available=true' : '/vaults';
    final res = await ApiService.get(path, token: token);
    if (res.statusCode != 200) throw Exception('Failed to load vaults');
    List<dynamic> list;
    try {
      final decoded = jsonDecode(res.body);
      list = decoded is List<dynamic> ? decoded : [];
    } catch (_) {
      list = [];
    }
    return list.map((e) => _vaultFromJson(e is Map<String, dynamic> ? e : <String, dynamic>{})).toList();
  }

  static Future<VaultModel> createVault(String token, String lockerNo, String location, double price, String slotDate, String timeSlot) async {
    final res = await ApiService.post(
      '/vaults',
      {'lockerNo': lockerNo, 'location': location, 'price': price, 'slotDate': slotDate, 'timeSlot': timeSlot},
      token: token,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to create vault');
    }
    final data = _tryDecode(res.body) ?? {};
    return _vaultFromJson(data);
  }

  static Future<VaultModel> updateVault(String token, String id, {String? lockerNo, String? location, double? price, String? slotDate, String? timeSlot, String? status}) async {
    final body = <String, dynamic>{};
    if (lockerNo != null) body['lockerNo'] = lockerNo;
    if (location != null) body['location'] = location;
    if (price != null) body['price'] = price;
    if (slotDate != null) body['slotDate'] = slotDate;
    if (timeSlot != null) body['timeSlot'] = timeSlot;
    if (status != null) body['status'] = status;
    final res = await ApiService.put('/vaults/$id', body, token: token);
    if (res.statusCode != 200) {
      final d = _tryDecode(res.body);
      throw Exception(d?['message']?.toString() ?? 'Failed to update vault');
    }
    final data = _tryDecode(res.body) ?? {};
    return _vaultFromJson(data);
  }

  static Future<void> deleteVault(String token, String id) async {
    final res = await ApiService.delete('/vaults/$id', token: token);
    if (res.statusCode != 200) {
      final d = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic>? : null;
      throw Exception(d?['message']?.toString() ?? 'Failed to delete vault');
    }
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
      status: j['status']?.toString() ?? 'available',
    );
  }
}
