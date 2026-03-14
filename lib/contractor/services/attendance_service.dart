import '../models/attendance_model.dart';
import '../../contractor/services/dio_service.dart';

import 'package:dio/dio.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  static AttendanceService get instance => _instance;

  Future<AttendanceHistoryResponse> fetchAttendanceHistory({
    required int userId,
    required int workspaceId,
    required int siteId,
    required String month,
    required String year,
    String type = 'monthly',
  }) async {
    try {
      final response = await DioService.instance.dio.get(
        '/Hrm/attendence-history',
        queryParameters: {
          'type': type,
          'employee_id': userId,
          'workspace_id': workspaceId,
          if (siteId > 0) 'site_id': siteId,
          'month': month.padLeft(2, '0'),
          'year': year,
        },
      );

      return AttendanceHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch attendance history: $e');
    }
  }

  Future<bool> insertAttendance({
    required String clockIn,
    required String clockOut,
    required String date,
    required int siteId,
    required int workspaceId,
    required int employeeId,
    required int userId,
    required int createdBy,
  }) async {
    // NOTE: Using 'attendence' (sic) to match the existing typo pattern in 'attendence-history'
    const fullUrl = 'https://app.ecoteamsolar.com/api/Hrm/admin-attendence-insert';
    try {
      final formData = FormData.fromMap({
        'clock_in': clockIn,
        'clock_out': clockOut,
        'date': date,
        'site_id': siteId.toString(),
        'workspace_id': workspaceId.toString(),
        'employee_id': employeeId.toString(),
        'user_id': userId.toString(),
        'created_by': createdBy.toString(),
      });

      print('Attempting POST to: $fullUrl');
      print('Payload: ${formData.fields}');

      final response = await DioService.instance.dio.post(
        fullUrl,
        data: formData,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
         final responseData = response.data;
         print('FULL RESPONSE DATA for INSERT: $responseData');

         // Check for various success indicators
         if (responseData['status'] == 'success' || 
             responseData['success'] == true || 
             responseData['status'] == 1 ||
             // Sometimes API just returns the object or a message
             (responseData is Map && responseData.containsKey('id')) ||
             (responseData is Map && responseData.containsKey('data'))) {
           return true;
         } else {
             // If we really can't find a success indicator but status code was 200/201, 
             // it might still be a success if the API is inconsistent. 
             // Let's trust 200/201 more if we can't find an explicit error.
             if (responseData['error'] == null && responseData['message'] == null) {
                print('Warning: No explicit success field, but status 200 and no error. Assuming success.');
                return true;
             }
            throw Exception('Failed to add attendance: ${responseData['message'] ?? responseData['error'] ?? 'Unknown error'}');
         }
      }
      return false;
    } on DioException catch (e) {
      print('DioError: ${e.message}');
      print('DioError URL: ${e.requestOptions.uri}');
      if (e.response?.statusCode == 404) {
         throw Exception('API endpoint not found (404). URL: $fullUrl');
      }
      rethrow;
    } catch (e) {
      print('General Error: $e');
      throw Exception('Failed to insert attendance: $e');
    }
  }

  Future<bool> updateAttendance({
    required int id,
    required String clockIn,
    required String clockOut,
    required String date,
    required int siteId,
    required int workspaceId,
    required int employeeId,
    required int userId,
    required int createdBy,
  }) async {
    // Reverting to 'attendence' (typo) as 'attendance' returned 404
    final fullUrl = 'https://app.ecoteamsolar.com/api/Hrm/admin-attendence-update/$id';
    try {
      final formData = FormData.fromMap({
        'clock_in': clockIn,
        'clock_out': clockOut,
        'date': date,
        'site_id': siteId.toString(),
        'workspace_id': workspaceId.toString(),
        'employee_id': employeeId.toString(),
        'user_id': userId.toString(),
        'created_by': createdBy.toString(),
      });

      print('Attempting POST to: $fullUrl');
      print('Payload: ${formData.fields}');

      final response = await DioService.instance.dio.post(
        fullUrl,
        data: formData,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
         final responseData = response.data;
         print('FULL RESPONSE DATA for UPDATE: $responseData');

         if (responseData['status'] == 'success' || 
             responseData['success'] == true ||
             responseData['status'] == 1 ||
             (responseData is Map && responseData.containsKey('id')) ||
             (responseData is Map && responseData.containsKey('data'))) {
           return true;
         } else {
             if (responseData['error'] == null && responseData['message'] == null) {
                print('Warning: No explicit success field, but status 200 and no error. Assuming success.');
                return true;
             }
            throw Exception('Failed to update attendance: ${responseData['message'] ?? responseData['error'] ?? 'Unknown error'}');
         }
      }
      return false;
    } catch (e) {
      print('Error updating attendance: $e');
      if (e is DioException) {
         print('DioError URL: ${e.requestOptions.uri}');
         print('DioError Status: ${e.response?.statusCode}');
         print('DioError Data: ${e.response?.data}'); // CRITICAL: This shows 422 validation errors
         
         if (e.response?.statusCode == 422) {
            // Throw a more helpful message
            final data = e.response?.data;
            if (data is Map && data['message'] != null) {
               throw Exception('Validation Error: ${data['message']}');
            }
         }
      }
      throw Exception('Failed to update attendance: $e');
    }
  }
  Future<List<DropdownEmployee>> fetchDropdownEmployees({
    required int workspaceId,
    required int siteId,
    required int createdBy,
    required int userId,
  }) async {
    try {
      final response = await DioService.instance.dio.post(
        '/Hrm/createData',
        data: {
          'workspace_id': workspaceId,
          'site_id': siteId,
          'created_by': createdBy,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['employees'] != null) {
          return (data['employees'] as List)
              .map((e) => DropdownEmployee.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch dropdown employees: $e');
    }
  }
}
