// services/supplier_category_service.dart
import 'dart:convert';
import 'package:ecoteam_app/admin/models/supplier_categary_model.dart';
import 'package:http/http.dart' as http;

class SupplierCategoryService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  static String? authToken;

  static Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  Future<SupplierCategoryResponse> getSupplierCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier-categories'),
        headers: await getHeaders(),
      );

      print('GET Categories Response Status: ${response.statusCode}');
      print('GET Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SupplierCategoryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load supplier categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSupplierCategories: $e');
      throw Exception('Failed to load supplier categories: $e');
    }
  }

  Future<SupplierCategory> createSupplierCategory(SupplierCategory category) async {
    try {
      // Create request data according to your API documentation
      final Map<String, dynamic> requestData = {
        'name': category.name,
        'description': category.description ?? '',
        'is_active': category.isActive, // This should be int (1 or 0)
        'site_id': category.siteId ?? 1, // Provide default value
        'created_by': category.createdBy,
        'workspace_id': category.workspaceId,
        'status': category.status,
      };

      print('Creating category with data: $requestData');
      print('URL: $baseUrl/supplier-categories');

      final response = await http.post(
        Uri.parse('$baseUrl/supplier-categories'),
        headers: await getHeaders(),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('CREATE Response Status: ${response.statusCode}');
      print('CREATE Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Handle API response based on your documentation
        if (responseData['status'] == 1) {
          // Check if data is a list or single object
          if (responseData['data'] is Map) {
            return SupplierCategory.fromJson(responseData['data']);
          } else if (responseData['data'] is List && responseData['data'].isNotEmpty) {
            return SupplierCategory.fromJson(responseData['data'].first);
          } else {
            // If no data in response, create from request data with new ID
            return SupplierCategory(
              id: responseData['id'] ?? DateTime.now().millisecondsSinceEpoch,
              name: category.name,
              description: category.description,
              siteId: category.siteId,
              createdBy: category.createdBy,
              workspaceId: category.workspaceId,
              isActive: category.isActive,
              status: category.status,
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            );
          }
        } else {
          throw Exception('API returned error: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create supplier category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createSupplierCategory: $e');
      throw Exception('Failed to create supplier category: $e');
    }
  }

  Future<SupplierCategory> updateSupplierCategory(SupplierCategory category) async {
    try {
      final Map<String, dynamic> requestData = {
        'name': category.name,
        'description': category.description ?? '',
        'is_active': category.isActive,
        'site_id': category.siteId,
        'created_by': category.createdBy,
        'workspace_id': category.workspaceId,
        'status': category.status,
      };

      print('Updating category ${category.id} with data: $requestData');

      final response = await http.put(
        Uri.parse('$baseUrl/supplier-categories/${category.id}'),
        headers: await getHeaders(),
        body: json.encode(requestData),
      );

      print('UPDATE Response Status: ${response.statusCode}');
      print('UPDATE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 1) {
          if (responseData['data'] is Map) {
            return SupplierCategory.fromJson(responseData['data']);
          } else {
            return category; // Return the updated category as is
          }
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to update supplier category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateSupplierCategory: $e');
      throw Exception('Failed to update supplier category: $e');
    }
  }

  Future<void> deleteSupplierCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/supplier-categories/$id'),
        headers: await getHeaders(),
      );

      print('DELETE Response Status: ${response.statusCode}');
      print('DELETE Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] != 1) {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to delete supplier category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteSupplierCategory: $e');
      throw Exception('Failed to delete supplier category: $e');
    }
  }
}