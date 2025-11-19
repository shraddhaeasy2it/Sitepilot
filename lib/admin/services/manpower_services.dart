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

  // GET dropdown data (manpower types, suppliers, sites)
  Future<DropdownData> getDropdownData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manpower/create-data'),
        headers: headers,
        body: json.encode({
          'site_id': 0,
          'workspace_id': 0,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final dropdownData = DropdownData.fromJson(data);
        
        // Update static maps
        typeMap = dropdownData.manpowerTypes;
        supplierMap = dropdownData.suppliers;
        siteMap = dropdownData.sites;
        
        return dropdownData;
      } else {
        throw Exception('Failed to load dropdown data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load dropdown data: $e');
    }
  }

  // GET all manpower records
  Future<List<ManpowerRecord>> getManpowerRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manpower'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ManpowerRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load manpower records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load manpower records: $e');
    }
  }

  // GET single manpower record
  Future<ManpowerRecord> getManpowerRecord(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manpower/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ManpowerRecord.fromJson(data);
      } else {
        throw Exception('Failed to load manpower record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load manpower record: $e');
    }
  }

  // POST new manpower record
  Future<ManpowerRecord> createManpowerRecord(ManpowerRecord record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/manpower'),
        headers: headers,
        body: json.encode(record.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ManpowerRecord.fromJson(data);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to create manpower record: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create manpower record: $e');
    }
  }

  // PUT update manpower record
  Future<ManpowerRecord> updateManpowerRecord(ManpowerRecord record) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/manpower/${record.id}'),
        headers: headers,
        body: json.encode(record.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ManpowerRecord.fromJson(data);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to update manpower record: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update manpower record: $e');
    }
  }

  // DELETE manpower record
  Future<void> deleteManpowerRecord(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/manpower/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to delete manpower record: ${errorBody['message'] ?? response.statusCode}');
      }
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