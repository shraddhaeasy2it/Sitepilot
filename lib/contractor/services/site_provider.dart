import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/company_site_provider.dart';
import 'package:flutter/material.dart';

class SiteProvider with ChangeNotifier {
  List<String> _sites = [];
  CompanySiteProvider? _companySiteProvider;
  VoidCallback? _listener;
  Map<String, double> _siteBalances = {};
  Map<String, double> _siteFuelQuantities = {};
  
  SiteProvider();
  
  void initialize(CompanySiteProvider companySiteProvider) {
    if (_companySiteProvider != null && _listener != null) {
      _companySiteProvider!.removeListener(_listener!);
    }
    _companySiteProvider = companySiteProvider;
    _listener = () {
      _initializeSites();
    };
    _companySiteProvider!.addListener(_listener!);
    _initializeSites();
  }
  
  @override
  void dispose() {
    if (_companySiteProvider != null && _listener != null) {
      _companySiteProvider!.removeListener(_listener!);
    }
    super.dispose();
  }
  
  Future<void> _initializeSites() async {
    if (_companySiteProvider != null) {
      final selectedCompanyId = _companySiteProvider!.selectedCompanyId;
      final allSites = _companySiteProvider!.allSites;
      final filteredSites = allSites
          .where((site) => site.companyId == selectedCompanyId)
          .toList();
      _sites = filteredSites.map((site) => site.name).toList();
      for (var site in _sites) {
        _siteBalances.putIfAbsent(site, () => 1000.0);
        _siteFuelQuantities.putIfAbsent(site, () => 500.0);
      }
      if (_sites.isEmpty) {
        _sites = ['Site A', 'Site B', 'Site C', 'Site D'];
        _siteBalances['Site A'] = 1000.0;
        _siteBalances['Site B'] = 800.0;
        _siteBalances['Site C'] = 1200.0;
        _siteBalances['Site D'] = 900.0;
        _siteFuelQuantities['Site A'] = 500.0;
        _siteFuelQuantities['Site B'] = 400.0;
        _siteFuelQuantities['Site C'] = 600.0;
        _siteFuelQuantities['Site D'] = 450.0;
      }
      notifyListeners();
    }
  }
  
  List<String> get sites => _sites;
  
  double getSiteBalance(String siteName) {
    return _siteBalances[siteName] ?? 0.0;
  }

  double getSiteFuelQuantity(String siteName) {
    return _siteFuelQuantities[siteName] ?? 0.0;
  }
  
  void updateSiteBalance(String siteName, double amount) {
    if (_siteBalances.containsKey(siteName)) {
      _siteBalances[siteName] = (_siteBalances[siteName] ?? 0.0) + amount;
      notifyListeners();
    }
  }

  void updateSiteFuelQuantity(String siteName, double quantity) {
    if (_siteFuelQuantities.containsKey(siteName)) {
      _siteFuelQuantities[siteName] = (_siteFuelQuantities[siteName] ?? 0.0) + quantity;
      notifyListeners();
    }
  }
  
  Map<String, double> get siteBalances => Map.from(_siteBalances);
  
  void addSite(String site) {
    if (!_sites.contains(site)) {
      _sites.add(site);
      _siteBalances[site] = 1000.0;
      notifyListeners();
    }
  }
  
  String? getSiteIdByName(String siteName) {
    if (_companySiteProvider != null) {
      try {
        final site = _companySiteProvider!.allSites.firstWhere(
          (site) => site.name == siteName,
          orElse: () => Site(id: '', name: '', address: '', companyId: ''),
        );
        return site.id.isNotEmpty ? site.id : null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}