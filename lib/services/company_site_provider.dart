import 'package:ecoteam_app/services/api_ser.dart';
import 'package:flutter/material.dart';

import 'package:ecoteam_app/models/dashboard/site_model.dart';

class CompanySiteProvider extends ChangeNotifier {
  String? _selectedCompany;
  List<String> _companies = [];
  List<Site> _sites = [];

  String? get selectedCompany => _selectedCompany;
  List<String> get companies => _companies;
  List<Site> get sites => _sites;

  Future<void> loadCompanies() async {
    _companies = await ApiService().fetchCompanies();
    notifyListeners();
  }

  void selectCompany(String company) {
    _selectedCompany = company;
    // For now, all sites are global; in future, filter by company
    loadSites();
    notifyListeners();
  }

  Future<void> loadSites() async {
    _sites = await ApiService().fetchSites();
    notifyListeners();
  }

  void addSite(Site site) async {
    await ApiService().addSite(site);
    await loadSites();
  }

  void deleteSite(String siteId) async {
    await ApiService().deleteSite(siteId);
    await loadSites();
  }

  void clearSelection() {
    _selectedCompany = null;
    _sites = [];
    notifyListeners();
  }
}