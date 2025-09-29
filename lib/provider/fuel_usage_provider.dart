import 'package:ecoteam_app/models/fuel_usage.dart';
import 'package:flutter/material.dart';

class FuelUsageProvider with ChangeNotifier {
  final List<FuelUsage> _usages = [];

  List<FuelUsage> get usages => _usages;

  void addUsage(FuelUsage usage) {
    _usages.add(usage);
    notifyListeners();
  }

  void updateUsage(String id, FuelUsage updatedUsage) {
    final index = _usages.indexWhere((usage) => usage.id == id);
    if (index != -1) {
      _usages[index] = updatedUsage;
      notifyListeners();
    }
  }

  void deleteUsage(String id) {
    _usages.removeWhere((usage) => usage.id == id);
    notifyListeners();
  }

  List<FuelUsage> getUsagesByMachineId(String machineId) {
    return _usages.where((usage) => usage.machineId == machineId).toList();
  }

  List<FuelUsage> getUsagesBySite(String site) {
    return _usages.where((usage) => usage.site == site).toList();
  }
}