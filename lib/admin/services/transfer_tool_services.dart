import 'dart:convert';
import 'package:http/http.dart' as http;

class TransfertoolService {
  static const String baseUrl =
      'https://sitepilot.easy2it.in/api';

  /// Fetch dropdown data
  static Future<Map<String, String>> fetchToSites({
    required int siteId,
    required int workspaceId,
    required int machineryId,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/general-transfers/create-data'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'site_id': siteId.toString(),
        'workspace_id': workspaceId.toString(),
        'transfer_type': 'Tools And Equipment',
        'machinery_id': machineryId.toString(),
        'user_id': userId.toString(),
      },
    );

    final jsonData = json.decode(response.body);

    if (response.statusCode == 200 &&
        jsonData['status'] == 'success') {
      return Map<String, String>.from(
        jsonData['data']['sites'] ?? {},
      );
    }

    throw Exception('Failed to load sites');
  }

  /// Create transfer
  static Future<void> createTransfer(Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/general-transfers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Transfer creation failed');
    }
  }

  /// Update transfer
  static Future<void> updateTransfer(
    int id,
    Map<String, String> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/general-transfers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Transfer update failed');
    }
  }

  /// Delete transfer
  static Future<void> deleteTransfer(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/general-transfers/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Transfer delete failed');
    }
  }
}
