import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import '../models/manpower_model.dart';
import 'package:flutter/foundation.dart';

class ManpowerService {
  static const String endpoint = '/manpower';
  
  // Static maps to store dropdown data
  static Map<int, String> typeMap = {};
  static Map<int, String> supplierMap = {};
  static Map<int, String> siteMap = {};
  

  // Helper method to handle API response
  dynamic _handleResponse(Response response, {bool isDropdownRequest = false}) {
    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');
    } else {
      // Force print in release mode if something weird is happening (temporary)
      print('API Response [${response.statusCode}]: ${response.data}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = response.data;
      
      // For dropdown request, the API returns data directly without status field
      if (isDropdownRequest) {
        return responseData; // Return the data directly
      }
      
      // For other requests, check for status field
      if (responseData is Map && responseData.containsKey('status')) {
        if (responseData['status'] == 'success') {
          return responseData;
        } else {
           // Some loose APIs might return status: "success" but sometimes just data
           // If it has 'data' lets imply success if status isn't explicitly error
           return responseData;
        }
      } else {
        // If no status field but response is 200, assume success
        if (kDebugMode) {
           print('Warning: No status field in response, assuming success');
        }
        return responseData;
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.statusMessage}');
    }
  }

  // GET dropdown data (manpower types, suppliers, sites)
  Future<DropdownData> getDropdownData() async {
    try {
      if (kDebugMode) {
         print('Fetching dropdown data from: ${DioService.instance.baseUrl}/manpower/create-data');
      }
      
      final response = await DioService.instance.dio.post(
        '$endpoint/create-data',
        data: {
          'site_id': 0,
          'workspace_id': 0,
        },
      );

      // Use isDropdownRequest = true to skip status check logic if it differs
      final responseData = _handleResponse(response, isDropdownRequest: true);
      
      // Check if we have the expected data
      if (responseData == null || (responseData is Map && responseData.isEmpty)) {
        throw Exception('Empty dropdown data received from API');
      }
      
      final dropdownData = DropdownData.fromJson(responseData);
      
      // Update static maps
      typeMap = dropdownData.manpowerTypes;
      supplierMap = dropdownData.suppliers;
      siteMap = dropdownData.sites;
      
      if (kDebugMode) {
        print('Dropdown data loaded successfully:');
        print('  Types: ${typeMap.length} items');
        print('  Suppliers: ${supplierMap.length} items');
        print('  Sites: ${siteMap.length} items');
      }
      
      return dropdownData;
    } catch (e) {
      if (kDebugMode) print('Error loading dropdown data: $e');
      throw Exception('Failed to load dropdown data: $e');
    }
  }

  // GET all manpower records
  Future<List<ManpowerRecord>> getManpowerRecords() async {
    try {
      if (kDebugMode) print('Fetching manpower records from: ${DioService.instance.baseUrl}$endpoint');
      
      final response = await DioService.instance.dio.get(endpoint);

      final responseData = _handleResponse(response);
      
      // Extract data array from response
      final List<dynamic> dataList = responseData['data'] ?? 
                                   responseData['records'] ?? 
                                   responseData['list'] ?? 
                                   [];
      
      if (kDebugMode) print('Found ${dataList.length} records');
      
      return dataList.map((json) => ManpowerRecord.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading manpower records: $e');
      throw Exception('Failed to load manpower records: $e');
    }
  }

  // GET manpower records by site and workspace
  Future<List<ManpowerRecord>> getManpowerRecordsBySiteAndWorkspace(int siteId, int workspaceId) async {
    try {
      final url = '$endpoint?site_id=$siteId&workspace_id=$workspaceId';
      if (kDebugMode) print('Fetching records from: $url');
      
      final response = await DioService.instance.dio.get(url);

      final responseData = _handleResponse(response);
      
      // Extract data array from response
      final List<dynamic> dataList = responseData['data'] ?? 
                                   responseData['records'] ?? 
                                   responseData['list'] ?? 
                                   [];
      
      return dataList.map((json) => ManpowerRecord.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading records by site/workspace: $e');
      throw Exception('Failed to load manpower records: $e');
    }
  }

  // GET single manpower record
  Future<ManpowerRecord> getManpowerRecord(int id) async {
    try {
      final response = await DioService.instance.dio.get('$endpoint/$id');

      final responseData = _handleResponse(response);
      
      // Try different possible keys for the data
      final Map<String, dynamic> recordData = responseData['data'] ?? 
                                            responseData['record'] ?? 
                                            responseData;
      
      return ManpowerRecord.fromJson(recordData);
    } catch (e) {
      throw Exception('Failed to load manpower record: $e');
    }
  }

  // POST new manpower record
  Future<ManpowerRecord> createManpowerRecord(ManpowerRecord record) async {
    try {
      final jsonPayload = record.toJson();
      if (kDebugMode) {
        print('Creating record with payload: $jsonPayload');
      }

      final response = await DioService.instance.dio.post(
        endpoint,
        data: jsonPayload,
      );

      final responseData = _handleResponse(response);
      
      // Try different possible keys for the data
      final Map<String, dynamic> createdData = responseData['data'] ?? 
                                              responseData['record'] ?? 
                                              responseData;
      
      return ManpowerRecord.fromJson(createdData);
    } on DioException catch (e) {
      if (e.response != null) {
        print('API Error Response [${e.response?.statusCode}]: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to create manpower record: $e');
    }
  }

  // PUT update manpower record
  Future<ManpowerRecord> updateManpowerRecord(ManpowerRecord record) async {
    try {
      final response = await DioService.instance.dio.put(
        '$endpoint/${record.id}',
        data: record.toJson(),
      );

      final responseData = _handleResponse(response);
      
      // Try different possible keys for the data
      final Map<String, dynamic> updatedData = responseData['data'] ?? 
                                              responseData['record'] ?? 
                                              responseData;
      
      return ManpowerRecord.fromJson(updatedData);
    } catch (e) {
      throw Exception('Failed to update manpower record: $e');
    }
  }

  // DELETE manpower record
  Future<void> deleteManpowerRecord(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$endpoint/$id');

      _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to delete manpower record: $e');
    }
  }

  // Helper method to get type name by ID
  static String getTypeNameById(int id) {
    return typeMap[id] ?? 'Unknown Type';
  }

  // Helper method to get supplier name by ID
  static String getSupplierNameById(int id) {
    return supplierMap[id] ?? 'Unknown Supplier';
  }

  // Helper method to get site name by ID
  static String getSiteNameById(int id) {
    return siteMap[id] ?? 'Unknown Site';
  }

  // Helper method to get type ID by name
  static int getTypeIdByName(String name) {
    return typeMap.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == name.toLowerCase(),
          orElse: () => MapEntry(0, ''),
        )
        .key;
  }

  // Helper method to get supplier ID by name
  static int getSupplierIdByName(String name) {
    return supplierMap.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == name.toLowerCase(),
          orElse: () => MapEntry(0, ''),
        )
        .key;
  }

  // Helper method to get site ID by name
  static int getSiteIdByName(String name) {
    return siteMap.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == name.toLowerCase(),
          orElse: () => MapEntry(0, ''),
        )
        .key;
  }
}