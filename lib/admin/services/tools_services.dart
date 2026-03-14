import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class ToolsApiService {
  // Endpoints
  static const String toolsEndpoint = '/tools';
  static const String materialsCategoryEndpoint = '/materials/category';

  // Get materials by category
  Future<List<MaterialModel>> getMaterialsByCategory(int categoryId) async {
    try {
      final response = await DioService.instance.dio.get('$materialsCategoryEndpoint/$categoryId');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List<dynamic> materialsJson = [];

        if (data is List) {
          materialsJson = data;
        } else if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            materialsJson = data['data'];
          } else if (data.containsKey('materials') && data['materials'] is List) {
             materialsJson = data['materials'];
          }
        }
        
        return materialsJson.map((json) => MaterialModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty list instead of throwing to allow tools to load even if materials fail
      print('Error loading materials: $e'); 
      return [];
    }
  }

  // Get all tools
  Future<List<ToolModel>> getTools({int? siteId, int? workspaceId}) async {
    try {
      String url = toolsEndpoint;
      List<String> queryParams = [];
      if (siteId != null) queryParams.add('site_id=$siteId');
      if (workspaceId != null) queryParams.add('workspace_id=$workspaceId');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await DioService.instance.dio.get(url);

      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        List<dynamic> toolsJson = [];
        
        if (responseData is List) {
           toolsJson = responseData;
        } else if (responseData is Map) {
           if (responseData['data'] is List) {
             toolsJson = responseData['data'];
           } else if (responseData['tools'] is List) {
             toolsJson = responseData['tools'];
           }
        } 

        return toolsJson.map((json) => ToolModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tools: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load tools: $e');
    }
  }

  // Create new tool
  Future<ToolModel> createTool(ToolModel tool) async {
    try {
      final response = await DioService.instance.dio.post(
        toolsEndpoint,
        data: tool.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        return ToolModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create tool: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create tool: $e');
    }
  }

  // Update tool
  Future<ToolModel> updateTool(int toolId, ToolModel tool) async {
    try {
      final response = await DioService.instance.dio.put(
        '$toolsEndpoint/$toolId',
        data: tool.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ToolModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update tool: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update tool: $e');
    }
  }

  // Delete tool
  Future<void> deleteTool(int toolId) async {
    try {
      final response = await DioService.instance.dio.delete('$toolsEndpoint/$toolId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete tool: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete tool: $e');
    }
  }
}