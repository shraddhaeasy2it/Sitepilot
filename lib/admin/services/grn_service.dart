import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/grn_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class GRNService {
  static const String grnEndpoint = '/grn';

  Future<List<GRNModel>> getGRNs({
    String? workspaceId,
    String? siteId,
    String? poId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;
      if (poId != null) queryParams['po_id'] = poId;
      if (status != null) queryParams['status'] = status;

      print('Fetching GRNs from: $grnEndpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(
        grnEndpoint,
        queryParameters: queryParams,
      );

      print('GRN response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> grnList;

        if (responseData is List) {
          grnList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          grnList = responseData['data'];
        } else {
          grnList = [];
        }

        return grnList.map((json) => GRNModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load GRNs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading GRNs: $e');
      throw Exception('Failed to load GRNs: $e');
    }
  }

  Future<Map<String, dynamic>> createGRN(Map<String, dynamic> data) async {
    try {
      print('Creating GRN at: $grnEndpoint');
      print('Request data: $data');

      final response = await DioService.instance.dio.post(
        grnEndpoint,
        data: data,
      );

      print('Create GRN response status: ${response.statusCode}');
      print('Create GRN response body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create GRN: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating GRN: $e');
      throw Exception('Failed to create GRN: $e');
    }
  }

  Future<Map<String, dynamic>> getGRNCreateData({
    required int workspaceId,
    required int siteId,
  }) async {
    try {
      final endpoint = '$grnEndpoint/create-data';
      final formData = FormData.fromMap({
        'workspace_id': workspaceId,
        'site_id': siteId,
      });

      print('Fetching GRN create data from: $endpoint with data: ${formData.fields}');
      final response = await DioService.instance.dio.post(
        endpoint,
        data: formData,
      );

      print('GRN Create Data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load GRN create data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading GRN create data: $e');
      throw Exception('Failed to load GRN create data: $e');
    }
  }

  Future<Map<String, dynamic>> getGRNPODetails({
    required int poId,
  }) async {
    try {
      final endpoint = '$grnEndpoint/po-details';
      final queryParams = {
        'po_id': poId,
      };

      print('Fetching GRN PO details from: $endpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(
        endpoint,
        queryParameters: queryParams,
      );

      print('GRN PO Details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load GRN PO details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading GRN PO details: $e');
      throw Exception('Failed to load GRN PO details: $e');
    }
  }

  Future<Map<String, dynamic>> updateGRN(int grnId, Map<String, dynamic> data) async {
    try {
      final endpoint = '$grnEndpoint/$grnId';
      print('Updating GRN at: $endpoint');
      print('Request data: $data');

      final response = await DioService.instance.dio.put(
        endpoint,
        data: data,
      );

      print('Update GRN response status: ${response.statusCode}');
      print('Update GRN response body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to update GRN: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating GRN: $e');
      throw Exception('Failed to update GRN: $e');
    }
  }
}
