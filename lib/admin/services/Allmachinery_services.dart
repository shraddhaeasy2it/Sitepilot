import 'dart:convert';
import 'package:ecoteam_app/admin/models/Allmachinery_model.dart';
import 'package:http/http.dart' as http;


class MachineryService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api/machineries';

  Future<MachineryResponse> getMachineries() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return MachineryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load machineries');
    }
  }

  Future<AllMachinery> createMachinery(AllMachinery machinery) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(machinery.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return AllMachinery.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Failed to create machinery');
    }
  }

  Future<AllMachinery> updateMachinery(AllMachinery machinery) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${machinery.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(machinery.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return AllMachinery.fromJson(data['data'] ?? data);
    } else {
      throw Exception('Failed to update machinery');
    }
  }

  Future<void> deleteMachinery(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete machinery');
    }
  }
}