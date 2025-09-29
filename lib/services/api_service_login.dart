import 'dart:convert';
import 'package:ecoteam_app/models/dashboard_model.dart';
import 'package:ecoteam_app/models/site_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';

  static var sites;

  // Login method
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');


      if (response.body.trim().startsWith('<!DOCTYPE')) {
        return {
          'success': false,
          'error': 'Server returned HTML instead of JSON. Check API endpoint.',
        };
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveUserData(responseData);
        return {'success': true, 'data': responseData};
      } else {
        final errorMsg =
            responseData['message'] ??
            'Login failed (Status ${response.statusCode})';
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {
        'success': false,
        'error':
            'Network error: ${e.toString().replaceAll('FormatException: ', '')}',
      };
    }
  }

  static Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString('auth_token', data['token']);
    }
    if (data['user'] != null) {
      await prefs.setString('user_data', jsonEncode(data['user']));
    }
  }

  // Get all items
  static Future<Map<String, dynamic>> getData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/login'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to fetch data',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Create item
  static Future<Map<String, dynamic>> createItem(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/login'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to create item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Update item
  static Future<Map<String, dynamic>> updateItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse('$baseUrl/login/$id'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Delete item
  static Future<Map<String, dynamic>> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/items/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete item',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future deleteSite(String id) async {}

  Future addSite(Site newSite) async {}

  Future<DashboardData?> fetchDashboardData() async {
    return null;
  }
}