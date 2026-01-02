import 'dart:convert';
import 'dart:io';
import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://sitepilot.easy2it.in/api';
  
  // Static list to maintain sites across the app with company association
  static List<Site> _sites = [
    Site(id: 'site1', name: 'Site A', companyId: 'ABC Construction'),
    Site(id: 'site2', name: 'Site B', companyId: 'ABC Construction'),
    Site(id: 'site3', name: 'Site C', companyId: 'XYZ Builders'),
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

  Future<bool> addCompany(String companyName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Check if company already exists
    if (_companies.any((company) => company.toLowerCase() == companyName.toLowerCase())) {
      return false; // Company already exists
    }
    _companies.add(companyName);
    return true;
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

  Future<bool> updateCompany(String oldCompanyName, String newCompanyName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _companies.indexWhere((company) => company == oldCompanyName);
    if (index != -1) {
      // Check if new company name already exists
      if (_companies.any((company) => company.toLowerCase() == newCompanyName.toLowerCase() && company != oldCompanyName)) {
        return false; // New company name already exists
      }
      _companies[index] = newCompanyName;
      // Update companyId in all sites that belong to this company
      for (var i = 0; i < _sites.length; i++) {
        if (_sites[i].companyId == oldCompanyName) {
          _sites[i] = Site(
            id: _sites[i].id,
            name: _sites[i].name,
            description: _sites[i].description,
            companyId: newCompanyName,
          );
        }
      }
      return true;
    }
    return false; // Company not found
  }

  Future<bool> deleteCompany(String companyName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final initialLength = _companies.length;
    _companies.removeWhere((company) => company == companyName);
    // Also remove all sites that belong to this company
    _sites.removeWhere((site) => site.companyId == companyName);
    return _companies.length < initialLength; // Return true if company was actually deleted
  }

 

  // Clock In/Out API
  Future<Map<String, dynamic>> clockInOut({
    required String type,
    required String userId,
    required String workspaceId,
    required String siteId,
    required String latitude,
    required String longitude,
    String? attendanceId,
    File? imageFile, // Added image parameter
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_token');

      // Handle siteId that might be like "site6" or just "6"
      var parsedSiteId = siteId;
      if (parsedSiteId.toLowerCase().startsWith('site')) {
        parsedSiteId = parsedSiteId.substring(4);
      }

      var uri = Uri.parse('$baseUrl/Hrm/clock-in-out');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['type'] = type;
      request.fields['user_id'] = userId;
      request.fields['workspace_id'] = workspaceId;
      request.fields['site_id'] = parsedSiteId;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      if (attendanceId != null) {
        request.fields['attendence_id'] = attendanceId;
      }

      if (imageFile != null) {
        // Determine field name based on type
        String imageField = type == 'clockin' ? 'clock_in_image' : 'clock_out_image';
        
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        
        var multipartFile = http.MultipartFile(
          imageField,
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      print('ClockInOut Request Fields: ${request.fields}');
      if (imageFile != null) print('ClockInOut Image: ${imageFile.path}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('ClockInOut Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        String errorMessage = 'Failed to $type. Status: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          // Parsing failed, use default message
        }
        return {
          'success': false, 
          'message': errorMessage
        };
      }
    } catch (e) {
      print('ClockInOut Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}