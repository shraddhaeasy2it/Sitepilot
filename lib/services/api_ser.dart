import 'package:ecoteam_app/models/dashboard/dashboard_model.dart';
import 'package:ecoteam_app/models/dashboard/site_model.dart';


class ApiService {
  // Static list to maintain sites across the app
  static List<Site> _sites = [
    Site(id: 'site1', name: 'Site A', address: '123 Main St'),
    Site(id: 'site2', name: 'Site B', address: '456 Oak Ave'),
    Site(id: 'site3', name: 'Site C', address: '789 Pine Blvd'),
  ];
List<String> _companies = [];
  // Getter for sites
  static List<Site> get sites => List.unmodifiable(_sites);

  // Method to update sites
  static void updateSites(List<Site> newSites) {
    _sites = List.from(newSites);
  }

  Future<DashboardData> fetchDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DashboardData(
      selectedSiteId: _sites.isNotEmpty ? _sites.first.id : '',
      sites: _sites,
      totalProjects: 5,
      totalWorkers: 42,
      totalPicking: 18,
      totalInspection: 7,
    );
  }

  Future<List<Site>> fetchSites() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sites;
  }

  Future<bool> addSite(Site site) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Check if site with same name already exists
    if (_sites.any((existingSite) => existingSite.name.toLowerCase() == site.name.toLowerCase())) {
      return false; // Site already exists
    }
    _sites.add(site);
    return true;
  }

  Future<bool> deleteSite(String siteId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final initialLength = _sites.length;
    _sites.removeWhere((site) => site.id == siteId);
    return _sites.length < initialLength; // Return true if site was actually deleted
  }

  Future<List<Map<String, dynamic>>> fetchWorkersForSite(String siteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'name': 'John Smith',
        'position': 'Foreman',
        'phone': '+1234567890',
        'email': 'john.smith@example.com',
        'status': 'Active',
        'siteId': 'site1',
      },
      {
        'id': '2',
        'name': 'Maria Garcia',
        'position': 'Worker',
        'phone': '+1234567891',
        'email': 'maria.garcia@example.com',
        'status': 'Active',
        'siteId': 'site2',
      },
      {
        'id': '3',
        'name': 'Robert Johnson',
        'position': 'Supervisor',
        'phone': '+1234567892',
        'email': 'robert.johnson@example.com',
        'status': 'Active',
        'siteId': 'site1',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> fetchMaterialsForSite(String siteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'name': 'Cement',
        'quantity': '50 bags',
        'unit': 'bags',
        'price': 25.0,
        'siteId': 'site1',
      },
      {
        'id': '2',
        'name': 'Steel Beams',
        'quantity': '20 pieces',
        'unit': 'pieces',
        'price': 150.0,
        'siteId': 'site2',
      },
      {
        'id': '3',
        'name': 'Bricks',
        'quantity': '1000 pieces',
        'unit': 'pieces',
        'price': 0.5,
        'siteId': 'site1',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> fetchPaymentsForSite(String siteId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {
        'id': '1',
        'description': 'Material Payment',
        'amount': 5000.0,
        'status': 'Pending',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'siteId': 'site1',
      },
      {
        'id': '2',
        'description': 'Labor Payment',
        'amount': 3000.0,
        'status': 'Approved',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'siteId': 'site2',
      },
      {
        'id': '3',
        'description': 'Equipment Rental',
        'amount': 1500.0,
        'status': 'Paid',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'siteId': 'site1',
      },
    ];
  }

  // Method to fetch companies
  Future<List<String>> fetchCompanies() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _companies;
  }
}