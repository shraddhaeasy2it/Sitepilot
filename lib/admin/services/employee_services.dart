import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecoteam_app/admin/models/employee_model.dart';

class ApiService {
  static const String baseUrl = 'YOUR_BASE_URL'; // Replace with your base URL
  static const String apiKey = 'YOUR_API_KEY'; // If needed

  // Fetch employees from API
  static Future<List<Employee>> fetchEmployees({int siteId = 0, int workspaceId = 3}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/employer?site_id=$siteId&workspace_id=$workspaceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Employee.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }

  // Add new employee
  static Future<Employee> addEmployee(Employee employee) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/employee'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode(employee.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Employee.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to add employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Update employee
  static Future<Employee> updateEmployee(Employee employee) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/employee/${employee.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode(employee.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Employee.fromJson(responseData['data']);
      } else {
        throw Exception('Failed to update employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating employee: $e');
      rethrow;
    }
  }

  // Delete employee
  static Future<bool> deleteEmployee(String employeeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/employee/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }
}