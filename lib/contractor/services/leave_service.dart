import 'package:ecoteam_app/contractor/models/leave_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class LeaveService {
  // GET: Fetch all leaves
  static Future<List<Leave>> fetchLeaves({
    required int userId,
    required int workspaceId,
    int? siteId,
  }) async {
    try {
      // Endpoint based on GET image: /api/Hrm/leaves
      final String endpoint = '/Hrm/leaves?user_id=$userId&workspace_id=$workspaceId&site_id=${siteId ?? 3}';
      
      final response = await ApiService.getRequest(endpoint);

      if (response['status'] == 1 && response['data'] is List) {
        return (response['data'] as List)
            .map((e) => Leave.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching leaves: $e');
      return [];
    }
  }

  // POST: Create a new leave request
  static Future<Map<String, dynamic>> requestLeave({
    required int userId,
    required int workspaceId,
    int? siteId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? remark,
  }) async {
    try {
      // Ensure all fields are sent as strings to match "Text" type in Postman/FormData
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        'workspace_id': workspaceId.toString(),
        'site_id': (siteId ?? 3).toString(),
        'leave_type_id': leaveTypeId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'leave_reason': reason,
        'remark': remark ?? '',
      });

      final response = await DioService.instance.dio.post(
        '/Hrm/leaves',
        data: formData,
      );

      if (response.data['status'] == 1) {
        return {'success': true, 'message': response.data['message'] ?? 'Leave applied successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to apply leave'};
    } catch (e) {
      print('Error requesting leave: $e');
      if (e is DioException) {
         return {'success': false, 'message': e.response?.data['message'] ?? e.message ?? 'Network error'};
      }
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // PUT: Update an existing leave request
  static Future<Map<String, dynamic>> updateLeave({
    required int id,
    required int userId,
    required int workspaceId,
    int? siteId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? remark,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        'workspace_id': workspaceId.toString(),
        'site_id': (siteId ?? 3).toString(),
        'leave_type_id': leaveTypeId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'leave_reason': reason,
        'remark': remark ?? '',
        '_method': 'PUT',
      });

      final response = await DioService.instance.dio.post(
        '/Hrm/leaves/$id',
        data: formData,
      );

      if (response.data['status'] == 1) {
        return {'success': true, 'message': response.data['message'] ?? 'Leave updated successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to update leave'};
    } catch (e) {
      print('Error updating leave: $e');
      if (e is DioException) {
         return {'success': false, 'message': e.response?.data['message'] ?? e.message ?? 'Network error'};
      }
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // DELETE: Delete a leave request
  static Future<Map<String, dynamic>> deleteLeave({
    required int id,
    required int userId,
    required int workspaceId,
    int? siteId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        'workspace_id': workspaceId.toString(),
        'site_id': (siteId ?? 3).toString(),
        '_method': 'DELETE',
      });

      final response = await DioService.instance.dio.post(
        '/Hrm/leaves/$id',
        data: formData,
      );

      if (response.data['status'] == 1) {
        return {'success': true, 'message': response.data['message'] ?? 'Leave deleted successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to delete leave'};
    } catch (e) {
      print('Error deleting leave: $e');
      if (e is DioException) {
         return {'success': false, 'message': e.response?.data['message'] ?? e.message ?? 'Network error'};
      }
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }
}
