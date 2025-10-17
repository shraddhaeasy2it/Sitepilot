import 'dart:convert';
import 'package:ecoteam_app/admin/models/tools_model.dart';
import 'package:http/http.dart' as http;


class ApiService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get materials by category
  Future<List<MaterialModel>> getMaterialsByCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/materials/category/$categoryId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          final List<dynamic> materialsJson = data['data'];
          return materialsJson.map((json) => MaterialModel.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load materials: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load materials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load materials: $e');
    }
  }

  // Get all tools
  Future<List<ToolModel>> getTools() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tools'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> toolsJson = json.decode(response.body);
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
      final response = await http.post(
        Uri.parse('$baseUrl/tools'),
        headers: headers,
        body: json.encode(tool.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ToolModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to create tool: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create tool: $e');
    }
  }

  // Update tool
  Future<ToolModel> updateTool(int toolId, ToolModel tool) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tools/$toolId'),
        headers: headers,
        body: json.encode(tool.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ToolModel.fromJson(data['data']);
      } else {
        throw Exception('Failed to update tool: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update tool: $e');
    }
  }

  // Delete tool
  Future<void> deleteTool(int toolId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tools/$toolId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete tool: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete tool: $e');
    }
  }
}