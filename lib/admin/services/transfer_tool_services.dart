import 'dart:convert';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class TransfertoolService {
  // Base URL handled by DioService

  /// Fetch dropdown data
  static Future<Map<String, String>> fetchToSites({
    required int siteId,
    required int workspaceId,
    required int machineryId,
    required int userId,
  }) async {
    final response = await DioService.instance.dio.post(
      '/general-transfers/create-data',
      data: {
        'site_id': siteId,
        'workspace_id': workspaceId,
        'transfer_type': 'Tools And Equipment',
        'tools_and_equipment_id': machineryId,
        'user_id': userId,
      },
    );

    if (response.statusCode == 200) {
       final data = response.data;
       if (data['status'] == 'success') {
          final sitesData = data['data']['sites'] as Map<String, dynamic>? ?? {};
          return sitesData.map((key, value) => MapEntry(key, value.toString()));
       }
    }
    throw Exception('Failed to load sites');
  }

  /// Create transfer
  static Future<void> createTransfer(Map<String, dynamic> body) async {
    final response = await DioService.instance.dio.post(
      '/general-transfers',
      data: body,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Transfer creation failed');
    }
  }

  /// Update transfer
  static Future<void> updateTransfer(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await DioService.instance.dio.put(
      '/general-transfers/$id',
      data: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Transfer update failed');
    }
  }

  /// Delete transfer
  static Future<void> deleteTransfer(int id) async {
    final response = await DioService.instance.dio.delete(
      '/general-transfers/$id',
    );

    if (response.statusCode != 200) {
      throw Exception('Transfer delete failed');
    }
  }
}

