import 'package:ecoteam_app/contractor/models/machine_model.dart';
import 'package:ecoteam_app/contractor/models/fuel_model.dart';
import 'package:ecoteam_app/contractor/services/site_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];
  List<Machine> get machines => _machines;
  
  void addMachine(Machine machine) {
    _machines.add(machine);
    notifyListeners();
  }
  
  void updateMachine(String id, String name, String type, String currentSite) {
    final index = _machines.indexWhere((m) => m.id == id);
    if (index != -1) {
      _machines[index] = Machine(
        id: id,
        name: name,
        type: type,
        currentSite: currentSite,
      );
      notifyListeners();
    }
  }
  
  void deleteMachine(String id) {
    _machines.removeWhere((m) => m.id == id);
    notifyListeners();
  }
  
  Machine? getMachineById(String id) {
    try {
      return _machines.firstWhere((machine) => machine.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get machines for a specific site
  List<Machine> getMachinesForSite(String site) {
    return _machines.where((machine) => machine.currentSite == site).toList();
  }
  
  // Transfer machine to a new site
  void transferMachine(String machineId, String newSite) {
    final index = _machines.indexWhere((m) => m.id == machineId);
    if (index != -1) {
      _machines[index] = _machines[index].copyWith(currentSite: newSite);
      notifyListeners();
    }
  }
}