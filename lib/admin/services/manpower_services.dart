import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manpower_model.dart';

class ManpowerService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  // Static maps to store dropdown data
  static Map<int, String> typeMap = {};
  static Map<int, String> supplierMap = {};
  static Map<int, String> siteMap = {};
  
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper method to handle API response - UPDATED
  Map<String, dynamic> _handleResponse(http.Response response, {bool isDropdownRequest = false}) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // For dropdown request, the API returns data directly without status field
        if (isDropdownRequest) {
          return responseData; // Return the data directly
        }
        
        // For other requests, check for status field
        if (responseData.containsKey('status')) {
          if (responseData['status'] == 'success') {
            return responseData;
          } else {
            throw Exception('API Error: ${responseData['message'] ?? 'Unknown error'}');
          }
        } else {
          // If no status field but response is 200, assume success
          print('Warning: No status field in response, assuming success');
          return responseData;
        }
      } catch (e) {
        print('Error parsing JSON: $e');
        throw Exception('Failed to parse API response: $e');
      }
    } else {
      throw Exception('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  // GET dropdown data (manpower types, suppliers, sites) - FIXED
  Future<DropdownData> getDropdownData() async {
    try {
      print('Fetching dropdown data from: $baseUrl/manpower/create-data');
      
      final response = await http.post(
        Uri.parse('$baseUrl/manpower/create-data'),
        headers: headers,
        body: json.encode({
          'site_id': 0,
          'workspace_id': 0,
        }),
      );

      print('Dropdown API Response Status: ${response.statusCode}');
      
      // Use isDropdownRequest = true to skip status check
      final responseData = _handleResponse(response, isDropdownRequest: true);
      
      print('Parsed response data: $responseData');
      
      // Check if we have the expected data
      if (responseData.isEmpty) {
        throw Exception('Empty dropdown data received from API');
      }
      
      final dropdownData = DropdownData.fromJson(responseData);
      
      // Update static maps
      typeMap = dropdownData.manpowerTypes;
      supplierMap = dropdownData.suppliers;
      siteMap = dropdownData.sites;
      
      print('Dropdown data loaded successfully:');
      print('  Types: ${typeMap.length} items');
      print('  Suppliers: ${supplierMap.length} items');
      print('  Sites: ${siteMap.length} items');
      
      return dropdownData;
    } catch (e) {
      print('Error loading dropdown data: $e');
      throw Exception('Failed to load dropdown data: $e');
    }
  }

  // GET all manpower records - UPDATED
  Future<List<ManpowerRecord>> getManpowerRecords() async {
    try {
      print('Fetching manpower records from: $baseUrl/manpower');
      
      final response = await http.get(
        Uri.parse('$baseUrl/manpower'),
        headers: headers,
      );

      final responseData = _handleResponse(response);
      
      // Extract data array from response
      // Try different possible keys
      final List<dynamic> dataList = responseData['data'] ?? 
                                   responseData['records'] ?? 
                                   responseData['list'] ?? 
                                   [];
      
      print('Found ${dataList.length} records');
      
      return dataList.map((json) => ManpowerRecord.fromJson(json)).toList();
    } catch (e) {
      print('Error loading manpower records: $e');
      throw Exception('Failed to load manpower records: $e');
    }
  }

  // GET manpower records by site and workspace - UPDATED
  Future<List<ManpowerRecord>> getManpowerRecordsBySiteAndWorkspace(int siteId, int workspaceId) async {
    try {
      final url = '$baseUrl/manpower?site_id=$siteId&workspace_id=$workspaceId';
      print('Fetching records from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      final responseData = _handleResponse(response);
      
      // Extract data array from response
      final List<dynamic> dataList = responseData['data'] ?? 
                                   responseData['records'] ?? 
                                   responseData['list'] ?? 
                                   [];
      
      return dataList.map((json) => ManpowerRecord.fromJson(json)).toList();
    } catch (e) {
      print('Error loading records by site/workspace: $e');
      throw Exception('Failed to load manpower records: $e');
    }
  }

  // GET single manpower record - UPDATED
  Future<ManpowerRecord> getManpowerRecord(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manpower/$id'),
        headers: headers,
      );

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

  // POST new manpower record - UPDATED
  Future<ManpowerRecord> createManpowerRecord(ManpowerRecord record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manpower'),
        headers: headers,
        body: json.encode(record.toJson()),
      );

      final responseData = _handleResponse(response);
      
      // Try different possible keys for the data
      final Map<String, dynamic> createdData = responseData['data'] ?? 
                                              responseData['record'] ?? 
                                              responseData;
      
      return ManpowerRecord.fromJson(createdData);
    } catch (e) {
      throw Exception('Failed to create manpower record: $e');
    }
  }

  // PUT update manpower record - UPDATED
  Future<ManpowerRecord> updateManpowerRecord(ManpowerRecord record) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/manpower/${record.id}'),
        headers: headers,
        body: json.encode(record.toJson()),
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

  // DELETE manpower record - UPDATED
  Future<void> deleteManpowerRecord(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/manpower/$id'),
        headers: headers,
      );

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