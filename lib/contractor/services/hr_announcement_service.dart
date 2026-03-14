import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:ecoteam_app/contractor/models/announcement_model.dart';

class HrAnnouncementService {
  static const String _endpoint = '/Hrm/announcements';

  // Fetch all announcements
  static Future<List<AnnouncementModel>> getAnnouncements({
    required int workspaceId,
    String? siteId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'workspace_id': workspaceId,
      };
      if (siteId != null) {
        queryParams['site_id'] = siteId;
      }

      final response = await DioService.instance.dio.get(
        _endpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 1 && data['data'] != null) {
          final List<dynamic> listJson = data['data'];
          List<AnnouncementModel> allItems = listJson.map((json) => AnnouncementModel.fromJson(json)).toList();
          
          return allItems;
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch announcements');
    }
  }

  // Create announcement
  static Future<Map<String, dynamic>> createAnnouncement(Map<String, dynamic> data) async {
    try {
      final formData = FormData.fromMap(data);
      final response = await DioService.instance.dio.post(
        _endpoint,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'message': 'Announcement created successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};

    } on DioException catch (e) {
      String msg = 'Failed to create announcement';
      if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update announcement
  static Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> data) async {
    try {
      data['_method'] = 'PUT'; // For Laravel method spoofing
      final formData = FormData.fromMap(data);
      
      final response = await DioService.instance.dio.post(
        '$_endpoint/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
          return {'success': true, 'message': 'Announcement updated successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};
    } on DioException catch (e) {
      String msg = 'Failed to update announcement';
       if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete announcement
  static Future<bool> deleteAnnouncement(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$_endpoint/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Fetch create-data (projects)
  static Future<Map<String, String>> getAnnouncementCreateData({
    required int workspaceId,
    required String siteId,
  }) async {
    try {
      final response = await DioService.instance.dio.post(
        '$_endpoint/create-data',
        data: {
          'workspace_id': workspaceId,
          'site_id': siteId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final Map<String, dynamic> projectsJson = response.data['projects'] ?? {};
        return projectsJson.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
