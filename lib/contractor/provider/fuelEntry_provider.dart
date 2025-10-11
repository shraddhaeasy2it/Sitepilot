import 'package:ecoteam_app/contractor/models/fuel_model.dart';
import 'package:ecoteam_app/contractor/services/site_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FuelEntryProvider with ChangeNotifier {
  List<FuelEntry> _entries = [];
  List<FuelEntry> get entries => _entries;
  
  List<FuelEntry> getEntriesForMachine(String machineId) {
    return _entries.where((entry) => entry.machineId == machineId).toList();
  }
  
  List<FuelEntry> getEntriesForSite(String site) {
    return _entries.where((entry) => entry.site == site).toList();
  }
  
  void addEntry(FuelEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }
  
  void updateEntry(String id, FuelEntry updatedEntry) {
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
  
  // Transfer fuel entry to a new site
  void transferFuelEntry(String entryId, String newSite, BuildContext context) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex != -1) {
      final entry = _entries[entryIndex];
      final oldSite = entry.site;
      final total = entry.total;
      
      // Update the entry with the new site
      _entries[entryIndex] = entry.copyWith(site: newSite);
      
      // Update site balances and fuel quantities
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);
      siteProvider.updateSiteBalance(oldSite, total); // Add back to old site
      siteProvider.updateSiteBalance(newSite, -total); // Deduct from new site
      siteProvider.updateSiteFuelQuantity(oldSite, entry.litre); // Add back quantity to old site
      siteProvider.updateSiteFuelQuantity(newSite, -entry.litre); // Deduct quantity from new site
      
      notifyListeners();
    }
  }
  
  // Transfer a specific quantity of fuel between sites
  void transferFuelQuantity({
    required String entryId,
    required String destinationSite,
    required double quantity,
    required BuildContext context,
  }) {
    final entryIndex = _entries.indexWhere((e) => e.id == entryId);
    if (entryIndex == -1) return;
    
    final entry = _entries[entryIndex];
    final sourceSite = entry.site;
    
    if (quantity <= 0 || quantity > entry.litre) {
      return; // Invalid quantity
    }
    
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    
    if (quantity == entry.litre) {
      // Transfer the entire entry
      transferFuelEntry(entryId, destinationSite, context);
      return;
    }
    
    // Calculate proportional cost
    final costPerLiter = entry.cost;
    final transferredCost = costPerLiter * quantity;
    final transferredTotal = transferredCost;
    
    // Create a new entry for the transferred fuel
    final newEntry = FuelEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      machineId: entry.machineId,
      fuelType: entry.fuelType,
      cost: costPerLiter,
      litre: quantity,
      total: transferredTotal,
      site: destinationSite,
      date: DateTime.now(),
    );
    
    // Update the original entry
    final remainingQuantity = entry.litre - quantity;
    final remainingTotal = entry.total - transferredTotal;
    
    _entries[entryIndex] = entry.copyWith(
      litre: remainingQuantity,
      total: remainingTotal,
    );
    
    // Add the new entry
    _entries.add(newEntry);
    
    // Update site balances and fuel quantities
    siteProvider.updateSiteBalance(sourceSite, transferredTotal); // Add back to source site
    siteProvider.updateSiteBalance(destinationSite, -transferredTotal); // Deduct from destination site
    siteProvider.updateSiteFuelQuantity(sourceSite, -quantity); // Deduct quantity from source site
    siteProvider.updateSiteFuelQuantity(destinationSite, quantity); // Add quantity to destination site
    
    notifyListeners();
  }
}