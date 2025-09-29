import 'package:ecoteam_app/models/dashboard_model.dart';
import 'package:ecoteam_app/models/site_model.dart';



class ApiService {
  // Static list to maintain sites across the app with company association
  static List<Site> _sites = [
    Site(id: 'site1', name: 'Site A', address: '123 Main St', companyId: 'ABC Construction'),
    Site(id: 'site2', name: 'Site B', address: '456 Oak Ave', companyId: 'ABC Construction'),
    Site(id: 'site3', name: 'Site C', address: '789 Pine Blvd', companyId: 'XYZ Builders'),
  ];
  
  // Static list to maintain companies
  static final List<String> _companies = [
    'ABC Construction',
    'XYZ Builders',
    'Urban Developers',
    'Infra Projects',
  ];
  
  // Getter for sites
  static List<Site> get sites => List.unmodifiable(_sites);
  
  // Getter for companies
  static List<String> get companies => List.unmodifiable(_companies);

  // Method to update sites
  static void updateSites(List<Site> newSites) {
    _sites = List.from(newSites);
  }

  Future<DashboardData> fetchDashboardData({String? companyId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Filter sites by company if companyId is provided
    List<Site> filteredSites = companyId != null
        ? _sites.where((site) => site.companyId == companyId).toList()
        : _sites;
    
    return DashboardData(
      selectedSiteId: filteredSites.isNotEmpty ? filteredSites.first.id : '',
      sites: filteredSites,
      totalProjects: 5,
      totalWorkers: 42,
      totalPicking: 18,
      totalInspection: 7,
    );
  }

  Future<List<Site>> fetchSites({String? companyId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // If companyId is provided, filter sites by company
    if (companyId != null) {
      return _sites.where((site) => site.companyId == companyId).toList();
    }
    
    return _sites;
  }
  
  Future<List<String>> fetchCompanies() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _companies;
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
  
  Future<bool> updateSite(Site updatedSite) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _sites.indexWhere((site) => site.id == updatedSite.id);
    if (index != -1) {
      _sites[index] = updatedSite;
      return true;
    }
    return false; // Site not found
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

  // This method is already defined above
  // Removed duplicate fetchCompanies() method
}