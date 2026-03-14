import 'dart:convert';
import 'dart:io';
import 'package:ecoteam_app/contractor/models/dashboard_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/models/user_notification_model.dart';

import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://app.ecoteamsolar.com/api';
  
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

 

  // Generic GET Request
  static Future<Map<String, dynamic>> getRequest(String endpoint) async {
    try {
      final response = await DioService.instance.dio.get(endpoint);

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else if (response.data is String) {
          try {
            return jsonDecode(response.data);
          } catch (e) {
            return {'status': 0, 'message': 'Invalid JSON response'};
          }
        }
        return {'status': 1, 'data': response.data};
      } else {
        return {'status': 0, 'message': 'Request failed with status: ${response.statusCode}'};
      }
    } catch (e) {
      print('API GET Error: $e');
      return {'status': 0, 'message': 'Error: $e'};
    }
  }

  // Generic POST Request
  static Future<Map<String, dynamic>> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await DioService.instance.dio.post(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
            return response.data;
        } else if (response.data is String) {
             try {
                return jsonDecode(response.data);
             } catch(e) {
                return {'status': 0, 'message': 'Invalid JSON response'};
             }
        }
        return {'status': 1, 'data': response.data};
      } else {
        return {'status': 0, 'message': 'Request failed with status: ${response.statusCode}'};
      }
    } catch (e) {
      print('API POST Error: $e');
      return {'status': 0, 'message': 'Error: $e'};
    }
  }

  // Clock In/Out API
  Future<Map<String, dynamic>> clockInOut({
    required String type,
    required String userId,
    required String employeeId,
    required String workspaceId,
    required String siteId,
    required String latitude,
    required String longitude,
    String? attendanceId,
    File? imageFile, 
  }) async {
    try {
      // Handle siteId that might be like "site6" or just "6"
      var parsedSiteId = siteId;
      if (parsedSiteId.toLowerCase().startsWith('site')) {
        parsedSiteId = parsedSiteId.substring(4);
      }
      
      final Map<String, dynamic> body = {
        'type': type,
        'user_id': userId,
        'employee_id': employeeId,
        'workspace_id': workspaceId,
        'site_id': parsedSiteId,
        'latitude': latitude,
        'longitude': longitude,
        if (attendanceId != null) 'attendence_id': attendanceId,
      };

      if (imageFile != null) {
        String imageField = type == 'clockin' ? 'clock_in_image' : 'clock_out_image';
        String fileName = imageFile.path.split('/').last;
        body[imageField] = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap(body);

      print('ClockInOut Request Data: $body');
      if (imageFile != null) print('ClockInOut Image: ${imageFile.path}');

      final response = await DioService.instance.dio.post(
        '/Hrm/clock-in-out',
        data: formData,
      );

      print('ClockInOut Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        // Dio functionality usually throws on non-200, so this might be redundant 
        // if using standard Dio options, but safe to keep for logic flow
        return {
          'success': false, 
          'message': 'Failed to $type. Status: ${response.statusCode}'
        };
      }
    } on DioException catch (e) {
       print('ClockInOut DioError: ${e.message}');
       String errorMessage = 'Failed to $type';
       if (e.response != null) {
         try {
            final errorData = e.response?.data;
             if (errorData is Map && errorData['message'] != null) {
               errorMessage = errorData['message'];
             }
         } catch (_) {}
       }
       return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('ClockInOut Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // General Transfers API (Reports)
  Future<List<dynamic>> fetchGeneralTransfers({
    required String siteId,
    required String workspaceId,
    String transferType = 'all',
  }) async {
    try {
      // Handle siteId that might be like "site6" or just "6"
      var parsedSiteId = siteId;
      if (parsedSiteId.toLowerCase().startsWith('site')) {
        parsedSiteId = parsedSiteId.substring(4);
      }

      final response = await DioService.instance.dio.get(
        '/general-transfers',
        queryParameters: {
          'site_id': parsedSiteId,
          'workspace_id': workspaceId,
          'transfer_type': transferType,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching transfers: $e');
      return [];
    }
  }
  // Fetch User Notifications
  Future<UserNotificationResponse?> fetchUserNotifications({
    int page = 1,
    String? siteId,
    int? workspaceId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      
      if (siteId != null) {
        // Handle if siteId comes as "site2" -> "2"
        var parsedSiteId = siteId;
        if (parsedSiteId.toLowerCase().startsWith('site')) {
           parsedSiteId = parsedSiteId.substring(4);
        }
        queryParams['site'] = parsedSiteId;
      }
      
      if (workspaceId != null) {
        queryParams['workspace'] = workspaceId;
      }

      final response = await DioService.instance.dio.get(
        '/UserNotifications',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserNotificationResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching notifications: $e');
      return null;
    }
  }
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await DioService.instance.dio.post(
        '/UserNotifications/$notificationId/read',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await DioService.instance.dio.post(
        '/UserNotifications/read-all',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
}