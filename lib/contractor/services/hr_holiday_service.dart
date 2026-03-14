import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:ecoteam_app/contractor/models/holiday_model.dart';

class HrHolidayService {
  static const String _endpoint = '/Hrm/holidays';

  // Fetch all holidays
  static Future<List<HolidayModel>> getHolidays({
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
          final List<dynamic> jsonList = data['data'];
          List<HolidayModel> items = jsonList.map((json) => HolidayModel.fromJson(json)).toList();
          return items;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching holidays: $e');
      throw Exception('Failed to fetch holidays');
    }
  }

  // Create holiday
  static Future<Map<String, dynamic>> createHoliday(Map<String, dynamic> data) async {
    try {
      final formData = FormData.fromMap(data);
      final response = await DioService.instance.dio.post(
        _endpoint,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'message': 'Holiday created successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};

    } on DioException catch (e) {
      print('Error creating holiday: ${e.response?.data}');
      String msg = 'Failed to create holiday';
      if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      print('Error creating holiday: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update holiday
  static Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> data) async {
    try {
      data['_method'] = 'PUT'; // For Laravel method spoofing
      final formData = FormData.fromMap(data);
      
      final response = await DioService.instance.dio.post(
        '$_endpoint/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
          return {'success': true, 'message': 'Holiday updated successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};
    } on DioException catch (e) {
      print('Error updating holiday: ${e.response?.data}');
      String msg = 'Failed to update holiday';
       if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      print('Error updating holiday: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete holiday
  static Future<bool> deleteHoliday(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$_endpoint/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting holiday: $e');
      return false;
    }
  }
}
