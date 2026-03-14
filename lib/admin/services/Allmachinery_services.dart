import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/Allmachinery_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class MachineryService {
  static const String endpoint = '/machineries';

  Future<MachineryResponse> getMachineries({int? workspaceId, int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      print('Fetching machineries from: $endpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(endpoint, queryParameters: queryParams);

      if (response.statusCode == 200) {
        // Handle raw list or wrapped data
        final data = response.data;
        if (data is Map<String, dynamic>) {
           return MachineryResponse.fromJson(data);
        } else if (data is List) {
           // Not matching model expectation usually, but just in case
           throw Exception('Unexpected response format');
        }
        return MachineryResponse.fromJson(data);
      } else {
        throw Exception('Failed to load machineries');
      }
    } catch (e) {
      throw Exception('Network error');
    }
  }

  Future<AllMachinery> createMachinery(AllMachinery machinery) async {
    try {
      final response = await DioService.instance.dio.post(
        endpoint,
        data: machinery.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return AllMachinery.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create machinery');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<AllMachinery> updateMachinery(AllMachinery machinery) async {
    try {
      final response = await DioService.instance.dio.put(
        '$endpoint/${machinery.id}',
        data: machinery.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return AllMachinery.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update machinery');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteMachinery(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$endpoint/$id');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete machinery');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}