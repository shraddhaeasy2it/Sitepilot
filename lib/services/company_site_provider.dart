import 'package:ecoteam_app/services/api_ser.dart';
import 'package:flutter/material.dart';
import 'package:ecoteam_app/models/site_model.dart';
import 'package:uuid/uuid.dart';

class CompanySiteProvider extends ChangeNotifier {
  String? _selectedCompanyId;
  List<String> _companies = [];
  final Map<String, List<Site>> _companySites = {}; // Map to store sites by company
  final Uuid _uuid = Uuid(); // For generating unique IDs

  String? get selectedCompanyId => _selectedCompanyId;
  String? get selectedCompanyName => _selectedCompanyId != null ? _companies[_companies.indexOf(_selectedCompanyId!)] : null;
  List<String> get companies => _companies;
  
  // Get sites for the currently selected company only
  List<Site> get sites => _selectedCompanyId != null 
      ? _companySites[_selectedCompanyId!] ?? [] 
      : [];
  
  // Get all sites across all companies
  List<Site> get allSites {
    List<Site> allSites = [];
    _companySites.forEach((_, siteList) {
      allSites.addAll(siteList);
    });
    return allSites;
  }

  Future<void> loadCompanies() async {
    _companies = await ApiService().fetchCompanies();
    // Initialize the sites map for each company
    for (var company in _companies) {
      if (!_companySites.containsKey(company)) {
        _companySites[company] = [];
      }
    }
    await loadAllSites();
    notifyListeners();
  }

  void selectCompany(String companyId) {
    _selectedCompanyId = companyId;
    notifyListeners();
  }

  // Load all sites and organize them by company
  Future<void> loadAllSites() async {
    List<Site> allSites = await ApiService().fetchSites();
    
    // Reset the company sites map
    for (var company in _companies) {
      _companySites[company] = [];
    }
    
    // Organize sites by company
    for (var site in allSites) {
      String companyId = site.companyId.isEmpty ? _companies.first : site.companyId;
      if (_companySites.containsKey(companyId)) {
        _companySites[companyId]!.add(site);
      } else if (_companies.isNotEmpty) {
        // Fallback to first company if the company doesn't exist
        _companySites[_companies.first]!.add(site);
      }
    }
    
    notifyListeners();
  }

  // Add a site to the currently selected company
  Future<void> addSite(Site site) async {
    if (_selectedCompanyId == null) return;
    
    // Create a new site with the current company ID
    final newSite = Site(
      id: 'site_${_uuid.v4()}',
      name: site.name,
      address: site.address,
      companyId: _selectedCompanyId!,
    );
    
    bool success = await ApiService().addSite(newSite);
    if (success) {
      if (!_companySites.containsKey(_selectedCompanyId)) {
        _companySites[_selectedCompanyId!] = [];
      }
      _companySites[_selectedCompanyId!]!.add(newSite);
      notifyListeners();
    }
  }

  // Delete a site from its company
  Future<void> deleteSite(String siteId) async {
    // Find which company the site belongs to
    String? companyId;
    Site? siteToDelete;
    
    for (var entry in _companySites.entries) {
      final site = entry.value.firstWhere(
        (s) => s.id == siteId,
        orElse: () => Site(id: '', name: '', address: '', companyId: ''),
      );
      
      if (site.id.isNotEmpty) {
        companyId = entry.key;
        siteToDelete = site;
        break;
      }
    }
    
    if (companyId != null && siteToDelete != null) {
      bool success = await ApiService().deleteSite(siteId);
      if (success) {
        _companySites[companyId]!.removeWhere((site) => site.id == siteId);
        notifyListeners();
      }
    }
  }

  void clearSelection() {
    _selectedCompanyId = null;
    notifyListeners();
  }
  
  // Update an existing site
  Future<void> updateSite(Site updatedSite) async {
    // Find which company the site belongs to
    String? companyId;
    int siteIndex = -1;
    
    for (var entry in _companySites.entries) {
      final index = entry.value.indexWhere((s) => s.id == updatedSite.id);
      
      if (index != -1) {
        companyId = entry.key;
        siteIndex = index;
        break;
      }
    }
    
    if (companyId != null && siteIndex != -1) {
      bool success = await ApiService().updateSite(updatedSite);
      if (success) {
        _companySites[companyId]![siteIndex] = updatedSite;
        notifyListeners();
      }
    }
  }
}