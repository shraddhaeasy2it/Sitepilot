import 'dart:convert';
import 'package:ecoteam_app/admin/models/MachineryCategory_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class MachineryCategoryService {
  // Base URL handled by DioService
  
  Future<List<MachineryCategory>> getCategories({int? workspaceId, int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      print('Fetching machinery categories from: /machinery-categories with params: $queryParams');
      final response = await DioService.instance.dio.get('/machinery-categories', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data);
        
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
      throw Exception('Failed to load categories');
    }
  }

  Future<MachineryCategory> createCategory(
    String name, 
    String description, {
    String status = '0',
    int? createdBy,
    int? workspaceId,
    int? siteId,
  }) async {
    try {
      final response = await DioService.instance.dio.post(
        '/machinery-categories',
        data: {
          'name': name,
          'description': description,
          'created_by': createdBy ?? 0,

          'workspace_id': workspaceId ?? 0,
          'site_id': siteId ?? 0,
          'is_active': 1,
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data);

        if (apiResponse.status == 1) {
          return MachineryCategory.fromJson(apiResponse.data);
        }
      }
      throw Exception('Failed to create category');
    } catch (e) {
      throw Exception('Failed to create category');
    }
  }

  Future<MachineryCategory> updateCategory(
    int id, 
    String name, 
    String description, {
    String status = '0',
    int? createdBy,
    int? workspaceId,
    int? siteId,
  }) async {
    try {
      final response = await DioService.instance.dio.put(
        '/machinery-categories/$id',
        data: {
          'name': name,
          'description': description,
          'site_id': siteId ?? 1,
          'created_by': createdBy ?? 0,
          'workspace_id': workspaceId ?? 0,
          'is_active': 1,
          'status': status,
        },
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse.fromJson(response.data);

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
      final response = await DioService.instance.dio.delete(
        '/machinery-categories/$id',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
      
      final apiResponse = ApiResponse.fromJson(response.data);
      if (apiResponse.status != 1) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}