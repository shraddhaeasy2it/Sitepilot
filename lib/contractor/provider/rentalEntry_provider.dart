import 'package:ecoteam_app/contractor/models/rental_model.dart';
import 'package:ecoteam_app/contractor/services/site_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class RentalEntryProvider with ChangeNotifier {
  List<RentalEntry> _entries = [];
  List<RentalEntry> get entries => _entries;
  
  List<RentalEntry> getEntriesForMachine(String machineId) {
    return _entries.where((entry) => entry.machineId == machineId).toList();
  }
  
  List<RentalEntry> getEntriesForSite(String site) {
    return _entries.where((entry) => entry.site == site).toList();
  }
  
  void addEntry(RentalEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }
  
  void updateEntry(String id, RentalEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      notifyListeners();
    }
  }
  
  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
  
  // Transfer rental entry to a new site
  void transferRentalEntry(String entryId, String newSite, BuildContext context) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex != -1) {
      final entry = _entries[entryIndex];
      final oldSite = entry.site;
      final total = entry.total;
      
      // Update the entry with the new site
      _entries[entryIndex] = entry.copyWith(site: newSite);
      
      // Update site balances
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);
      siteProvider.updateSiteBalance(oldSite, total); // Add back to old site
      siteProvider.updateSiteBalance(newSite, -total); // Deduct from new site
      
      notifyListeners();
    }
  }
}