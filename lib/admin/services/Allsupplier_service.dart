import 'dart:convert';
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:http/http.dart' as http;


class SupplierApiService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authorization header if needed
    // 'Authorization': 'Bearer your_token_here',
  };

  // GET - Get all suppliers
  static Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          final List<dynamic> suppliersData = responseData['data'];
          return suppliersData.map((json) => Supplier.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load suppliers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Get supplier by ID
  static Future<Supplier> getSupplierById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Get all supplier categories
  static Future<List<SupplierCategory>> getSupplierCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier-categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          final List<dynamic> categoriesData = responseData['data'];
          return categoriesData.map((json) => SupplierCategory.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load supplier categories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST - Create new supplier
  static Future<Supplier> addSupplier(Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suppliers'),
        headers: headers,
        body: json.encode(supplier.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to add supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT - Update supplier
  static Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/suppliers/${supplier.id}'),
        headers: headers,
        body: json.encode(supplier.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to update supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE - Delete supplier
  static Future<void> deleteSupplier(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] != 1) {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to delete supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}