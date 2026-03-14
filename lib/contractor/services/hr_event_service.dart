import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:ecoteam_app/contractor/models/event_model.dart';

class HrEventService {
  static const String _endpoint = '/Hrm/events';

  // Fetch all events
  static Future<List<EventModel>> getEvents({
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
          final List<dynamic> eventsJson = data['data'];
          List<EventModel> allEvents = eventsJson.map((json) => EventModel.fromJson(json)).toList();
          
          // Debug prints
          print("Fetched ${allEvents.length} events.");
          // Debug prints
          print("Fetched ${allEvents.length} events.");
          
          // Request: fetch all events, do not filter by site
          return allEvents;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Failed to fetch events');
    }
  }

  // Create event - Returns {success: bool, message: String}
  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    try {
      final formData = FormData.fromMap(data);
      final response = await DioService.instance.dio.post(
        _endpoint,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'message': 'Event created successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};

    } on DioException catch (e) {
      print('Error creating event: ${e.response?.data}');
      String msg = 'Failed to create event';
      if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      print('Error creating event: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update event
  static Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      data['_method'] = 'PUT'; // For Laravel method spoofing
      final formData = FormData.fromMap(data);
      
      final response = await DioService.instance.dio.post(
        '$_endpoint/$id',
        data: formData,
      );

      if (response.statusCode == 200) {
          return {'success': true, 'message': 'Event updated successfully'};
      }
      return {'success': false, 'message': response.statusMessage ?? 'Unknown error'};
    } on DioException catch (e) {
      print('Error updating event: ${e.response?.data}');
      String msg = 'Failed to update event';
       if (e.response?.data != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      print('Error updating event: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete event
  static Future<bool> deleteEvent(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$_endpoint/$id');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }
}
