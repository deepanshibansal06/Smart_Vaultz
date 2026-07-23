import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  String? role;
  String? name;
  String? email;
  String? phone;
  String? address;
  String? location;
  double walletBalance = 0;
  bool mpinSet = false; // from profile; MPIN saved in DB so we don't ask again

  static const _keyMpin = 'wallet_mpin';
  static const _keyUpiId = 'wallet_upi_id';

  Future<bool> hasMpinSet() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_keyMpin);
    return pin != null && pin.length == 4;
  }

  Future<bool> verifyMpin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyMpin);
    return stored != null && stored == pin;
  }

  Future<void> setMpin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMpin, pin);
    notifyListeners();
  }

  Future<String?> getUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUpiId);
  }

  Future<void> setUpiId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUpiId, id.trim());
    notifyListeners();
  }

  Future<void> login(String t, String r, {String? name, String? email}) async {
    token = t;
    role = r;
    this.name = name;
    this.email = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', t);
    await prefs.setString('role', r);
    if (name != null) await prefs.setString('name', name);
    if (email != null) await prefs.setString('email', email);

    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    role = prefs.getString('role');
    name = prefs.getString('name');
    email = prefs.getString('email');
    phone = prefs.getString('phone');
    address = prefs.getString('address');
    location = prefs.getString('location');
    walletBalance = prefs.getDouble('walletBalance') ?? 0;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final t = token;
    if (t == null) return;
    try {
      final profile = await UserService.getProfile(t);
      name = profile['name']?.toString();
      email = profile['email']?.toString();
      phone = profile['phone']?.toString();
      address = profile['address']?.toString();
      location = profile['location']?.toString();
      final b = profile['walletBalance'];
      walletBalance = (b is num) ? b.toDouble() : 0;
      mpinSet = profile['mpinSet'] == true;
      final prefs = await SharedPreferences.getInstance();
      if (name != null) await prefs.setString('name', name!);
      if (email != null) await prefs.setString('email', email!);
      if (phone != null) await prefs.setString('phone', phone!);
      if (address != null) await prefs.setString('address', address!);
      if (location != null) await prefs.setString('location', location!);
      await prefs.setDouble('walletBalance', walletBalance);
      notifyListeners();
    } catch (_) {}
  }

  void setWalletBalance(double value) {
    walletBalance = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('walletBalance', value);
    });
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    role = null;
    name = null;
    email = null;
    phone = null;
    address = null;
    location = null;
    walletBalance = 0;
    mpinSet = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('address');
    await prefs.remove('location');
    await prefs.remove('walletBalance');
    await prefs.remove(_keyMpin);
    await prefs.remove(_keyUpiId);
    notifyListeners();
  }

  bool get isAdmin => role == "superadmin";
  bool get isLoggedIn => token != null && token!.isNotEmpty;
}