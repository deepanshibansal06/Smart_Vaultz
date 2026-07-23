import 'package:flutter/material.dart';
import '../models/vault_model.dart';

class VaultProvider extends ChangeNotifier {
  List<VaultModel> vaults = [];

  /// Dummy lockers for demo when no data from backend.
  static final List<VaultModel> dummyVaults = [
    VaultModel(id: 'dummy-1', lockerNo: 'L001', location: 'Ground Floor', price: 50, slotDate: '', timeSlot: '9 AM - 6 PM'),
    VaultModel(id: 'dummy-2', lockerNo: 'L002', location: 'Ground Floor', price: 75, slotDate: '', timeSlot: '24 Hours'),
    VaultModel(id: 'dummy-3', lockerNo: 'L003', location: 'First Floor', price: 100, slotDate: '', timeSlot: '24 Hours'),
    VaultModel(id: 'dummy-4', lockerNo: 'L004', location: 'First Floor', price: 60, slotDate: '', timeSlot: '9 AM - 9 PM'),
    VaultModel(id: 'dummy-5', lockerNo: 'L005', location: 'Basement', price: 90, slotDate: '', timeSlot: '24 Hours'),
  ];

  /// Vaults to display: real data if any, otherwise dummy list for booking.
  List<VaultModel> get displayVaults =>
      vaults.isNotEmpty ? vaults : dummyVaults;

  void addVault(VaultModel vault) {
    vaults.add(vault);
    notifyListeners();
  }

  void deleteVault(String id) {
    vaults.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void updateVault(VaultModel vault) {
    final i = vaults.indexWhere((v) => v.id == vault.id);
    if (i >= 0) vaults[i] = vault;
    notifyListeners();
  }
}