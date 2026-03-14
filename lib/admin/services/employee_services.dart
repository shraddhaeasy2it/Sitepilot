import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/employee_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class ApiService {
  // Endpoints (Relative to DioService base URL: https://app.ecoteamsolar.com/api)
  static const String employeeEndpoint = '/employee';
  static const String createDataEndpoint = '/employee/create-data';
  static const String getDepartmentEndpoint = '/getdepartment';
  static const String getDesignationEndpoint = '/getdesignations';

  // Fetch employees list from API
  static Future<List<Employee>> fetchEmployees({
    required int workspaceId,
    int? siteId,
    int? createdBy,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'workspace_id': workspaceId,
      };
      if (siteId != null) queryParams['site_id'] = siteId;
      if (createdBy != null) queryParams['created_by'] = createdBy;

      print('Fetching employees from: $employeeEndpoint');

      final response = await DioService.instance.dio.get(
        employeeEndpoint,
        queryParameters: queryParams,
      );

      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

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
      final requestData = {
        'workspace_id': workspaceId,
        if (siteId != null) 'site_id': siteId,
        if (createdBy != null) 'created_by': createdBy,
      };
      
      print('🚀 fetchEmployeeCreationData Request: $requestData');

      final response = await DioService.instance.dio.post(
        createDataEndpoint,
        data: requestData,
      );

      print('Create Data Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 'success') {
          print('📝 fetchEmployeeCreationData Raw Response: $responseData');
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
      final response = await DioService.instance.dio.post(
        getDepartmentEndpoint,
        data: {
          'branch_id': branchId,
          'workspace_id': workspaceId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Convert to Map<String, String>
        Map<String, String> departments = {};
        if (responseData is Map) {
           responseData.forEach((key, value) {
             departments[key.toString()] = value.toString();
           });
        }
        
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
      final response = await DioService.instance.dio.post(
        getDesignationEndpoint,
        data: {
          'department_id': departmentId,
          'workspace_id': workspaceId,
        },
      );

      if (response.statusCode == 200) {
         final responseData = response.data;
         
        // Convert to Map<String, String>
        Map<String, String> designations = {};
        if (responseData is Map) {
           responseData.forEach((key, value) {
             designations[key.toString()] = value.toString();
           });
        }
        
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
  static Future<Employee> addEmployee(
    Employee employee, {
    File? avatarFile,
    Map<String, File>? documentFiles,
  }) async {
    try {
      final formData = FormData();
      
      // Add text fields
      final Map<String, String> fields = employee.toFormData();
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });

      // Add avatar if provided
      if (avatarFile != null) {
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatarFile.path),
        ));
      }

      // Add document files if provided
      if (documentFiles != null) {
        for (var entry in documentFiles.entries) {
          formData.files.add(MapEntry(
            'document[${entry.key}]',
            await MultipartFile.fromFile(entry.value.path),
          ));
        }
      }

      print('Adding employee with data: ${formData.fields}');

      final response = await DioService.instance.dio.post(
        employeeEndpoint,
        data: formData,
      );
      
      print('Add Employee Response Status: ${response.statusCode}');
      print('Add Employee Response Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success' || responseData.containsKey('id')) {
          return Employee.fromJson(responseData['data'] ?? responseData);
        } else {
          throw Exception('Failed to add employee: ${responseData['message']}');
        }
      } else {
        final responseData = response.data;
        throw Exception(responseData['message'] ?? 'Failed to add employee: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('❌ Add Employee HTTP ${e.response?.statusCode} error body: ${e.response?.data}');
      }
      print('Error adding employee: $e');
      rethrow;
    }
  }

  // Update employee
  static Future<Employee> updateEmployee(
    Employee employee, {
    File? avatarFile,
    Map<String, File>? documentFiles,
  }) async {
    try {
      final formData = FormData();

       // Add text fields
      final Map<String, String> fields = employee.toFormData();
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });
      
      formData.fields.add(const MapEntry('_method', 'PUT')); // For Laravel PUT via POST

      // Add avatar if provided
      if (avatarFile != null) {
        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatarFile.path),//375325
        ));
      }

      // Add document files if provided
      if (documentFiles != null) {
        for (var entry in documentFiles.entries) {
          formData.files.add(MapEntry(
            'document[${entry.key}]',
            await MultipartFile.fromFile(entry.value.path),
          ));
        }
      }

      print('Updating employee ${employee.id}');
      print('Update Payload Fields:');
      for (var field in formData.fields) {
        print('  ${field.key}: ${field.value}');
      }
      for (var file in formData.files) {
        print('  ${file.key}: Filename=${file.value.filename}, Length=${file.value.length}');
      }

      // Use POST with _method=PUT for Laravel when sending Multipart
      final response = await DioService.instance.dio.post(
        '$employeeEndpoint/${employee.id}',
        data: formData,
      );

      print('Update Employee Response Status: ${response.statusCode}');
      print('Update Employee Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success') {
          return Employee.fromJson(responseData['data'] ?? responseData);
        } else {
          throw Exception('Failed to update employee: ${responseData['message']}');
        }
      } else {
        final responseData = response.data;
        throw Exception(responseData['message'] ?? 'Failed to update employee: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
         print('API Error Response [${e.response?.statusCode}]: ${e.response?.data}');
      }
      print('Error updating employee (Dio Error): ${e.message}');
      rethrow;
    } catch (e) {
      print('Error updating employee: $e');
      rethrow;
    }
  }

  // Delete employee
  static Future<bool> deleteEmployee(String employeeId) async {
    try {
      final response = await DioService.instance.dio.delete('$employeeEndpoint/$employeeId');

      print('Delete Employee Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['status'] == 'success';
      } else {
        final responseData = response.data;
        throw Exception(responseData['message'] ?? 'Failed to delete employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting employee: $e');
      rethrow;
    }
  }

  // Get single employee by ID
  static Future<Employee> getEmployeeById(String id, {int? workspaceId}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'id': id,
      };
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;

      print('Fetching employee details from: $employeeEndpoint with params: $queryParams');

      final response = await DioService.instance.dio.get(
        employeeEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        var employeeData = responseData['data'] ?? responseData;

        if (employeeData is List && employeeData.isNotEmpty) {
          // Find the specific employee in the list if multiple returned
          final targetId = id.toString();
          employeeData = employeeData.firstWhere(
            (item) => item['id']?.toString() == targetId,
            orElse: () => employeeData.first,
          );
        }

        if (employeeData is Map<String, dynamic>) {
          return Employee.fromJson(employeeData);
        } else {
          throw Exception('Unexpected data format for employee: ${employeeData.runtimeType}');
        }
      } else {
        throw Exception('Failed to get employee: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting employee $id: $e');
      rethrow;
    }
  }
}