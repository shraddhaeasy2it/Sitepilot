import 'dart:convert';
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:http/http.dart' as http;
import 'package:ecoteam_app/contractor/services/api_service_login.dart';

class MachineryCategoryService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  Future<List<MachineryCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/machinery-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(json.decode(response.body));
        
        if (apiResponse.status == 1) {
          if (apiResponse.data is List) {
            return (apiResponse.data as List)
                .map((item) => MachineryCategory.fromJson(item))
                .toList();
          }
        }
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<MachineryCategory> createCategory(
    String name, 
    String description, {
    String status = '0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/machinery-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'created_by': await ApiService.getCurrentUserId(),
          'workspace_id': 0,
          'is_active': 1,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(json.decode(response.body));

        if (apiResponse.status == 1) {
          return MachineryCategory.fromJson(apiResponse.data);
        }
      }
      throw Exception('Failed to create category');
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<MachineryCategory> updateCategory(
    int id, 
    String name, 
    String description, {
    String status = '0',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/machinery-categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'site_id': 1,
          'created_by': await ApiService.getCurrentUserId(),
          'workspace_id': 0,
          'is_active': 1,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(json.decode(response.body));

        if (apiResponse.status == 1) {
          return MachineryCategory.fromJson(apiResponse.data);
        }
      }
      throw Exception('Failed to update category');
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/machinery-categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
      
      final apiResponse = ApiResponse.fromJson(json.decode(response.body));
      if (apiResponse.status != 1) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}