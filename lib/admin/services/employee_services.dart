import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecoteam_app/admin/models/employee_model.dart';

class ApiService {
  static const String baseUrl = 'http://sitepilot.easy2it.in'; // Replace with your base URL
  
  // Note: According to your documentation, the endpoint is '/api/employee'
  // and the parameters are 'site_id' and 'workspace_id'
  
  // Fetch employees from API
  static Future<List<Employee>> fetchEmployees({int siteId = 0, int workspaceId = 3}) async {
    try {
      final response = await http.get(
        // Corrected endpoint: '/api/employee' not '/api/employer'
        // Added proper parameters based on your documentation
        Uri.parse('$baseUrl/api/employee?site_id=$siteId&workspace_id=$workspaceId'),
        headers: {
          'Content-Type': 'application/json',
          // Add any required headers like authorization token if needed
        },
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        print('Response Data: $responseData');
        
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'];
          
          if (data is List) {
            // Check if data is not empty
            if (data.isEmpty) {
              print('No employees found');
              return [];
            }
            
            // Convert each JSON object to Employee model
            return data.map((json) {
              try {
                return Employee.fromJson(json);
              } catch (e) {
                print('Error parsing employee JSON $json: $e');
                // Return a default employee or handle as needed
                return Employee.fromJson({});
              }
            }).toList();
          } else {
            print('Data is not a list: ${data.runtimeType}');
            return [];
          }
        } else {
          throw Exception('API returned error: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found. Please check the API endpoint URL');
      } else {
        throw Exception('Failed to load employees. Status code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      print('JSON format error: $e');
      throw Exception('Invalid response format from server');
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
        },
        body: json.encode(employee.toJson()),
      );

      print('Add Employee Response Status: ${response.statusCode}');
      print('Add Employee Response Body: ${response.body}');

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
        },
        body: json.encode(employee.toJson()),
      );

      print('Update Employee Response Status: ${response.statusCode}');
      print('Update Employee Response Body: ${response.body}');

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
        },
      );

      print('Delete Employee Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['status'] == 'success';
      } else {
        return false;
      }
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }
}