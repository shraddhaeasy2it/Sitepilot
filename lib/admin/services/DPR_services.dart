

import 'dart:convert';
import 'dart:io';
import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';


class DPRService {
  static const String baseUrl = 'https://app.ecoteamsolar.com/api';

  static Future<DPRResponse> getDPRs({
    required String token,
    int? siteId,
    int? workspaceId,
    int? createdBy,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (siteId != null) queryParams['site_id'] = siteId.toString();
    if (workspaceId != null) queryParams['workspace_id'] = workspaceId.toString();
    if (createdBy != null) queryParams['created_by'] = createdBy.toString();

    final response = await DioService.instance.dio.get(
      '/daily-progress-reports',
      queryParameters: queryParams,
    );

    print('GET DPR Response: ${response.data}');

    if (response.statusCode == 200) {
      return DPRResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to load DPRs: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchCreateData({
    required int siteId,
    required int workspaceId,
    required int createdBy,
  }) async {
    try {
      final response = await DioService.instance.dio.post(
        '/daily-progress-reports/create-data',
        data: {
          'site_id': siteId,
          'workspace_id': workspaceId,
          'created_by': createdBy,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception('Failed to load create data');
      }
    } catch (e) {
      throw Exception('Error fetching create data: $e');
    }
  }

  static Future<DPRCreateResponse> createDPR({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    dynamic payload = data;
    
    // Check if we need to send as FormData (if items or files are present)
    if (data.containsKey('items') || data.containsKey('reference_file')) {
      final Map<String, dynamic> flatData = Map.from(data);
      final List<DPRItem> items = flatData.remove('items') as List<DPRItem>? ?? [];
      
      final formDataMap = Map<String, dynamic>.from(flatData);
      
      // Flatten items for PHP-style form-data: items[0][key]
      for (int i = 0; i < items.length; i++) {
        formDataMap['items[$i][material_id]'] = items[i].materialId;
        formDataMap['items[$i][quantity]'] = items[i].quantity;
        formDataMap['items[$i][unit]'] = items[i].unit;
        formDataMap['items[$i][remarks]'] = items[i].remarks;
      }

      // Handle Reference File if present
      if (data['reference_file'] != null) {
        final File file = data['reference_file'] as File;
        formDataMap['reference_file'] = await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        );
      }
      
      payload = FormData.fromMap(formDataMap);
    }

    try {
      final response = await DioService.instance.dio.post(
        '/daily-progress-reports',
        data: payload,
      );

      print('Create DPR Response: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data['success'] == false) {
          throw Exception(response.data['message'] ?? 'Unknown error occurred');
        }
        
        List<DPRItem>? localItems;
        if (data.containsKey('items')) {
            localItems = List.from(data['items']);
        }

        return DPRCreateResponse.fromJson(response.data, localItems: localItems);
      } else {
        throw Exception('Failed to create DPR: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Create DPR DioError: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response != null && e.response?.data is Map) {
        throw Exception(e.response?.data['message'] ?? e.response?.data.toString());
      }
      throw Exception('Server Error: ${e.message}');
    }
  }

  static Future<DPRCreateResponse> updateDPR({
    required String token,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    // Similar handling for update if needed, but PUT sometimes doesn't like multipart/form-data
    // However, if we need to upload a file in update, we often use POST with _method=PUT
    // For now, I'll implement it similarly.
    
    dynamic payload = data;
    if (data.containsKey('items') || data.containsKey('reference_file')) {
      final Map<String, dynamic> flatData = Map.from(data);
      final List<DPRItem> items = flatData.remove('items') as List<DPRItem>? ?? [];
      
      final formDataMap = Map<String, dynamic>.from(flatData);
      formDataMap['_method'] = 'PUT'; // Common PHP pattern for multipart PUT
      
      for (int i = 0; i < items.length; i++) {
        formDataMap['items[$i][material_id]'] = items[i].materialId;
        formDataMap['items[$i][quantity]'] = items[i].quantity;
        formDataMap['items[$i][unit]'] = items[i].unit;
        formDataMap['items[$i][remarks]'] = items[i].remarks;
      }

      if (data['reference_file'] != null) {
        final File file = data['reference_file'] as File;
        formDataMap['reference_file'] = await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        );
      }
      
      payload = FormData.fromMap(formDataMap);
      
      // Use POST with _method=PUT to handle multipart on some backends
      try {
        final response = await DioService.instance.dio.post(
          '/daily-progress-reports/$id',
          data: payload,
        );

        print('Update DPR Response (multipart): ${response.data}');

        if (response.statusCode == 200) {
          if (response.data['success'] == false) {
            throw Exception(response.data['message'] ?? 'Unknown error occurred');
          }
          
          List<DPRItem>? localItems;
          if (data.containsKey('items')) {
              localItems = List.from(data['items']);
          }

          return DPRCreateResponse.fromJson(response.data, localItems: localItems);
        } else {
          throw Exception('Failed to update DPR: ${response.statusCode}');
        }
      } on DioException catch (e) {
        print('Update DPR Multipart DioError: ${e.response?.statusCode} - ${e.response?.data}');
        if (e.response != null && e.response?.data is Map) {
          throw Exception(e.response?.data['message'] ?? e.response?.data.toString());
        }
        throw Exception('Server Error: ${e.message}');
      }
    } else {
      try {
        final response = await DioService.instance.dio.put(
          '/daily-progress-reports/$id',
          data: payload,
        );

        print('Update DPR Response: ${response.data}');

        if (response.statusCode == 200) {
          if (response.data['success'] == false) {
            throw Exception(response.data['message'] ?? 'Unknown error occurred');
          }

          List<DPRItem>? localItems;
          if (data.containsKey('items')) {
              localItems = List.from(data['items']);
          }

          return DPRCreateResponse.fromJson(response.data, localItems: localItems);
        } else {
          throw Exception('Failed to update DPR: ${response.statusCode}');
        }
      } on DioException catch (e) {
        print('Update DPR Put DioError: ${e.response?.statusCode} - ${e.response?.data}');
        if (e.response != null && e.response?.data is Map) {
          throw Exception(e.response?.data['message'] ?? e.response?.data.toString());
        }
        throw Exception('Server Error: ${e.message}');
      }
    }
  }

  static Future<void> deleteDPR({
    required String token,
    required int id,
  }) async {
    final response = await DioService.instance.dio.delete('/daily-progress-reports/$id');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete DPR: ${response.statusCode}');
    }
  }
}