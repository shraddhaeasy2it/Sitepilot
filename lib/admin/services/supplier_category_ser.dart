// services/supplier_category_service.dart
import 'dart:convert';
import 'package:ecoteam_app/admin/models/supplier_categary_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class SupplierCategoryService {
  // Base URL handled by DioService

  Future<SupplierCategoryResponse> getSupplierCategories() async {
    try {
      final response = await DioService.instance.dio.get('/supplier-categories');

      print('GET Categories Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
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
      print('Creating category with data: $requestData');
      print('URL: /supplier-categories');

      final response = await DioService.instance.dio.post(
        '/supplier-categories',
        data: requestData,
      ).timeout(const Duration(seconds: 30));

      print('CREATE Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        
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
        throw Exception('Failed to create supplier category: ${response.statusCode} - ${response.data}');
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

      final response = await DioService.instance.dio.put(
        '/supplier-categories/${category.id}',
        data: requestData,
      );

      print('UPDATE Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        
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
        throw Exception('Failed to update supplier category: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error in updateSupplierCategory: $e');
      throw Exception('Failed to update supplier category: $e');
    }
  }

  Future<void> deleteSupplierCategory(int id) async {
    try {
      final response = await DioService.instance.dio.delete(
        '/supplier-categories/$id',
      );

      print('DELETE Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
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