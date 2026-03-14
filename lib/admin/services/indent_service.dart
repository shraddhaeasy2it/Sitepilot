import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ecoteam_app/admin/models/indent_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:dio/dio.dart';

class IndentService {
  final String _baseUrl = 'https://app.ecoteamsolar.com';
  static const String getCreateDataEndpoint = '/indents/create-data';

  Future<List<IndentModel>> getIndents({
    required String? siteId,
    required int? workspaceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final queryParams = <String, String>{};
      if (siteId != null && siteId.isNotEmpty) {
        queryParams['site_id'] = siteId;
      }
      if (workspaceId != null) {
        queryParams['workspace_id'] = workspaceId.toString();
      }

      final uri = Uri.parse('$_baseUrl/api/indents').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> indentList = data['data'];
          return indentList.map((json) => IndentModel.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load indents with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching indents: $e');
      throw e;
    }
  }



  Future<IndentModel> createIndent(Map<String, dynamic> data, {File? referenceFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final uri = Uri.parse('$_baseUrl/api/indents');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add text fields
      data.forEach((key, value) {
        if (value != null && key != 'items' && key != 'assign_to') {
          request.fields[key] = value.toString();
        }
      });

      // Add items array
      if (data['items'] != null && data['items'] is List) {
        final items = data['items'] as List;
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item['material_id'] != null) request.fields['items[$i][material_id]'] = item['material_id'].toString();
          if (item['quantity'] != null) request.fields['items[$i][quantity]'] = item['quantity'].toString();
          if (item['unit'] != null) request.fields['items[$i][unit]'] = item['unit'].toString();
          if (item['price'] != null) request.fields['items[$i][price]'] = item['price'].toString();
          if (item['remarks'] != null) request.fields['items[$i][remarks]'] = item['remarks'].toString();
        }
      }

      // Add assign_to array
      if (data['assign_to'] != null && data['assign_to'] is List) {
        final assignTo = data['assign_to'] as List;
        for (int i = 0; i < assignTo.length; i++) {
          request.fields['assign_to[]'] = assignTo[i].toString();
        }
      }

      // Add file if exists
      if (referenceFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('reference_file', referenceFile.path),
        );
      }

      print('Creating indent with fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create Indent Response Code: ${response.statusCode}');
      print('Create Indent Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final insertedData = responseData['data'];
          if (insertedData != null) {
             return IndentModel.fromJson(insertedData);
          }
        }
        throw Exception('Failed to parse indent from success response.');
      } else {
        throw Exception('Failed to create indent: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating indent: $e');
      throw e;
    }
  }

  Future<IndentModel> updateIndent(int indentId, Map<String, dynamic> data, {File? referenceFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final uri = Uri.parse('$_baseUrl/api/indents/$indentId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT'; // Often needed for Laravel multipart updates

      // Add text fields
      data.forEach((key, value) {
        if (value != null && key != 'items' && key != 'assign_to') {
          request.fields[key] = value.toString();
        }
      });

      // Add items array
      if (data['items'] != null && data['items'] is List) {
        final items = data['items'] as List;
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          if (item['material_id'] != null) request.fields['items[$i][material_id]'] = item['material_id'].toString();
          if (item['quantity'] != null) request.fields['items[$i][quantity]'] = item['quantity'].toString();
          if (item['unit'] != null) request.fields['items[$i][unit]'] = item['unit'].toString();
          if (item['price'] != null) request.fields['items[$i][price]'] = item['price'].toString();
          if (item['remarks'] != null) request.fields['items[$i][remarks]'] = item['remarks'].toString();
        }
      }

      // Add assign_to array
      if (data['assign_to'] != null && data['assign_to'] is List) {
        final assignTo = data['assign_to'] as List;
        for (int i = 0; i < assignTo.length; i++) {
          request.fields['assign_to[]'] = assignTo[i].toString();
        }
      }

      // Add file if exists
      if (referenceFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('reference_file', referenceFile.path),
        );
      }

      print('Updating indent with fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Indent Response Code: ${response.statusCode}');
      print('Update Indent Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final updatedData = responseData['data'];
          if (updatedData != null) {
             return IndentModel.fromJson(updatedData);
          }
        }
        throw Exception('Failed to parse indent from success response.');
      } else {
        throw Exception('Failed to update indent: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating indent: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> getCreateData({
    required int workspaceId,
    required int siteId,
    required int createdBy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final requestData = {
        'workspace_id': workspaceId,
        'site_id': siteId,
        'created_by': createdBy,
      };

      print('Fetching indent create data from: $getCreateDataEndpoint with: $requestData');

      final response = await DioService.instance.dio.post(
        getCreateDataEndpoint,
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('Indent Create Data Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          return responseData['data'] ?? {};
        } else {
          throw Exception('API returned success=false: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to fetch indent create data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError fetching indent create data: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception('Failed to load indent form data: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('Error fetching indent create data: $e');
      throw Exception('Failed to load indent form data: $e');
    }
  }

  Future<bool> deleteIndent(int indentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final uri = Uri.parse('$_baseUrl/api/indents/$indentId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to delete indent: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete indent');
      }
    } catch (e) {
      print('Error deleting indent: $e');
      throw e;
    }
  }
}
