import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';

class ApiService {
  static const String baseUrl = 'https://sitepilot.easy2it.in';

  // Fetch employees list from API
  static Future<List<Employee>> fetchEmployees({
    required int workspaceId,
    int? siteId,
    int? createdBy,
  }) async {
    try {
      String url = '$baseUrl/api/employee?workspace_id=$workspaceId';
      if (siteId != null) {
        url += '&site_id=$siteId';
      }
      if (createdBy != null) {
        url += '&created_by=$createdBy';
      }

      print('Fetching employees from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'] ?? [];

          if (data.isNotEmpty) {
            return data.map((json) => Employee.fromJson(json)).toList();
          } else {
            print('No employees found in response');
            return [];
          }
        } else {
          throw Exception('API returned error: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load employees. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching employees: $e');
      rethrow;
    }
  }

  // Fetch employee creation data (with departments, branches, etc.)
  static Future<Employee> fetchEmployeeCreationData({
    required int workspaceId,
    int? siteId,
    int? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/employee/create-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'workspace_id': workspaceId,
          if (siteId != null) 'site_id': siteId,
          if (createdBy != null) 'created_by': createdBy,
        }),
      );

      print('Create Data Response Status: ${response.statusCode}');
      print('Create Data Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          return Employee.fromApiResponse(responseData);
        } else {
          throw Exception('Failed to fetch creation data: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to fetch creation data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching employee creation data: $e');
      rethrow;
    }
  }

  // Fetch departments based on branch
  static Future<Map<String, String>> fetchDepartments({
    required int branchId,
    required int workspaceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/getdepartment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'branch_id': branchId,
          'workspace_id': workspaceId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Convert to Map<String, String>
        Map<String, String> departments = {};
        responseData.forEach((key, value) {
          departments[key.toString()] = value.toString();
        });
        
        return departments;
      } else {
        throw Exception('Failed to fetch departments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching departments: $e');
      rethrow;
    }
  }

  // Fetch designations based on department
  static Future<Map<String, String>> fetchDesignations({
    required int departmentId,
    required int workspaceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/getdesignations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'department_id': departmentId,
          'workspace_id': workspaceId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Convert to Map<String, String>
        Map<String, String> designations = {};
        responseData.forEach((key, value) {
          designations[key.toString()] = value.toString();
        });
        
        return designations;
      } else {
        throw Exception('Failed to fetch designations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching designations: $e');
      rethrow;
    }
  }

  // Add new employee
  static Future<Employee> addEmployee(Employee employee, {File? avatarFile}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/employee'));
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add text fields
      final Map<String, String> formData = employee.toFormData();
      request.fields.addAll(formData);

      // Add avatar if provided
      if (avatarFile != null) {
        final mimeType = avatarFile.path.endsWith('.png') 
            ? MediaType('image', 'png') 
            : MediaType('image', 'jpeg');
            
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: mimeType,
        ));
      }

      print('Adding employee with data: ${request.fields}');
      if (avatarFile != null) {
        print('Adding avatar: ${avatarFile.path} with type: ${request.files.last.contentType}');
      }
      print('Request headers: ${request.headers}');

      final streamedResponse = await request.send();
      print('Request sent, waiting for response...');
      final response = await http.Response.fromStream(streamedResponse);

      print('Add Employee Response Status: ${response.statusCode}');
      print('Add Employee Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success' || responseData.containsKey('id')) {
          // API returns the created employee data
          return Employee.fromJson(responseData['data'] ?? responseData);
        } else {
          throw Exception('Failed to add employee: ${responseData['message']}');
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to add employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Update employee
  static Future<Employee> updateEmployee(Employee employee, {File? avatarFile}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/employee/${employee.id}'));
      
      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add text fields
      final Map<String, String> formData = employee.toFormData();
      formData['_method'] = 'PUT'; // For PUT request via POST
      request.fields.addAll(formData);

       // Add avatar if provided
      if (avatarFile != null) {
        final mimeType = avatarFile.path.endsWith('.png') 
            ? MediaType('image', 'png') 
            : MediaType('image', 'jpeg');
            
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: mimeType,
        ));
      }

      print('Updating employee ${employee.id} with data: ${request.fields}');
      if (avatarFile != null) {
         print('Updating avatar: ${avatarFile.path} with type: ${request.files.last.contentType}');
      }
      print('Request headers: ${request.headers}');

      final streamedResponse = await request.send();
      print('Request sent, waiting for response...');
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Employee Response Status: ${response.statusCode}');
      print('Update Employee Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          return Employee.fromJson(responseData['data'] ?? responseData);
        } else {
          throw Exception('Failed to update employee: ${responseData['message']}');
        }
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to update employee: ${response.statusCode}');
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
          'Accept': 'application/json',
        },
      );

      print('Delete Employee Response Status: ${response.statusCode}');
      print('Delete Employee Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['status'] == 'success';
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to delete employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }

  // Get single employee by ID
  static Future<Employee> getEmployeeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/employee/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Employee.fromJson(responseData['data'] ?? responseData);
      } else {
        throw Exception('Failed to get employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting employee: $e');
      rethrow;
    }
  }
}