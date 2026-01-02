import 'dart:convert';
import 'package:ecoteam_app/admin/models/DPR_model.dart';
import 'package:http/http.dart' as http;


class DPRService {
  static const String baseUrl = 'https://sitepilot.easy2it.in';

  static Future<DPRResponse> getDPRs({
    required String token,
    int? siteId,
    int? workspaceId,
    int? createdBy,
  }) async {
    final url = Uri.parse('$baseUrl/api/daily-progress-reports');
    
    Map<String, String> queryParams = {};
    if (siteId != null) queryParams['site_id'] = siteId.toString();
    if (workspaceId != null) queryParams['workspace_id'] = workspaceId.toString();
    if (createdBy != null) queryParams['created_by'] = createdBy.toString();

    final uri = Uri.https(url.authority, url.path, queryParams);
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return DPRResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load DPRs: ${response.statusCode}');
    }
  }

  static Future<DPRCreateResponse> createDPR({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/api/daily-progress-reports');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      final jsonResponse = json.decode(response.body);
      return DPRCreateResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to create DPR: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<DPRCreateResponse> updateDPR({
    required String token,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/api/daily-progress-reports/$id');
    
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return DPRCreateResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to update DPR: ${response.statusCode}');
    }
  }

  static Future<void> deleteDPR({
    required String token,
    required int id,
  }) async {
    final url = Uri.parse('$baseUrl/api/daily-progress-reports/$id');
    
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete DPR: ${response.statusCode}');
    }
  }
}