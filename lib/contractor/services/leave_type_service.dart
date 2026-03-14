import 'package:ecoteam_app/contractor/models/leave_type_model.dart';
import 'package:ecoteam_app/contractor/services/api_ser.dart';

class LeaveTypeService {
  
  // GET: Fetch all leave types
  static Future<List<LeaveType>> getLeaveTypes({
    required int userId,
    required int workspaceId,
    required int siteId,
  }) async {
    try {
      // Based on provided image: GET {{base_url}}/api/Hrm/leaves-types?user_id=10&workspace_id=3&site_id=3
      // ApiService.getRequest usually appends parameters or we might need to construct the query string manually depending on ApiService implementation.
      // Assuming ApiService.getRequest usage:
      final String endpoint = '/Hrm/leaves-types?user_id=$userId&workspace_id=$workspaceId&site_id=$siteId';
      
      final response = await ApiService.getRequest(endpoint);

      if (response['status'] == 1 && response['data'] is List) {
        return (response['data'] as List)
            .map((e) => LeaveType.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching leave types: $e');
      return [];
    }
  }

  // POST: Create a new leave type
  static Future<bool> createLeaveType({
    required int userId,
    required int workspaceId,
    required int siteId,
    required String title,
    required String days,
  }) async {
    try {
      final response = await ApiService.postRequest('/Hrm/leaves-types', {
        'user_id': userId,
        'workspace_id': workspaceId,
        'site_id': siteId,
        'title': title,
        'days': days,

      });

      if (response['status'] == 1) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating leave type: $e');
      return false;
    }
  }

  // PUT: Update an existing leave type
  static Future<bool> updateLeaveType({
    required int id,
    required int userId,
    required int workspaceId,
    required int siteId,
    required String title,
    required String days,
  }) async {
    try {
      // Using POST with _method = PUT as is common in PHP/Laravel APIs
      final response = await ApiService.postRequest('/Hrm/leaves-types/$id', {
        'user_id': userId,
        'workspace_id': workspaceId,
        'site_id': siteId,
        'title': title,
        'days': days,
        '_method': 'PUT',
      });

      if (response['status'] == 1) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating leave type: $e');
      return false;
    }
  }

  // DELETE: Delete a leave type
  static Future<bool> deleteLeaveType({
    required int id,
    required int userId,
    required int workspaceId,
    required int siteId,
  }) async {
    try {
      // Assuming typical DELETE pattern, often also POST with _method=DELETE if not using actual DELETE verb
      final response = await ApiService.postRequest('/Hrm/leaves-types/$id', {
        'user_id': userId,
        'workspace_id': workspaceId,
        'site_id': siteId,
        '_method': 'DELETE',
      });

      if (response['status'] == 1) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting leave type: $e');
      return false;
    }
  }
}
