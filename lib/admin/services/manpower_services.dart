// services/manpower_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mapower_model.dart';

class ManpowerTypeService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api/manpower-types';

  Future<List<ManpowerType>> getManpowerTypes() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('GET Status Code: ${response.statusCode}');
      print('GET Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => ManpowerType.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load manpower types: ${response.statusCode}');
      }
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<ManpowerType> createManpowerType(ManpowerType manpowerType) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(manpowerType.toJson()),
      );

      print('POST Status Code: ${response.statusCode}');
      print('POST Response: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ManpowerType.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create manpower type: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<ManpowerType> updateManpowerType(ManpowerType manpowerType) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${manpowerType.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(manpowerType.toUpdateJson()),
      );

      print('PUT Status Code: ${response.statusCode}');
      print('PUT Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ManpowerType.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to update manpower type: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteManpowerType(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('DELETE Status Code: ${response.statusCode}');
      print('DELETE Response: ${response.body}');
      print('DELETE ID: $id');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 204) {
        return true; // No content - successful delete
      } else {
        throw Exception('Failed to delete manpower type: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }
}