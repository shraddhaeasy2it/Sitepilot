// services/manpower_services.dart
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import '../models/mapowerType_model.dart';

class ManpowerTypeService {
  // Base URL handled by DioService

  Future<List<ManpowerType>> getManpowerTypes() async {
    try {
      final response = await DioService.instance.dio.get('/manpower-types');

      print('GET Status Code: ${response.statusCode}');
      print('GET Response: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = response.data;
        return jsonResponse.map((data) => ManpowerType.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load manpower types: ${response.statusCode}');
      }
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<ManpowerType> createManpowerType(ManpowerType manpowerType) async {
    try {
      final response = await DioService.instance.dio.post(
        '/manpower-types',
        data: manpowerType.toJson(),
      );

      print('POST Status Code: ${response.statusCode}');
      print('POST Response: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        return ManpowerType.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to create manpower type: ${response.statusCode}');
      }
    } catch (e) {
      print('POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<ManpowerType> updateManpowerType(ManpowerType manpowerType) async {
    try {
      final response = await DioService.instance.dio.put(
        '/manpower-types/${manpowerType.id}',
        data: manpowerType.toUpdateJson(),
      );

      print('PUT Status Code: ${response.statusCode}');
      print('PUT Response: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        return ManpowerType.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to update manpower type: ${response.statusCode}');
      }
    } catch (e) {
      print('PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> deleteManpowerType(int id) async {
    try {
      final response = await DioService.instance.dio.delete(
        '/manpower-types/$id',
      );

      print('DELETE Status Code: ${response.statusCode}');
      print('DELETE ID: $id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete manpower type: ${response.statusCode}');
      }
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }
}
