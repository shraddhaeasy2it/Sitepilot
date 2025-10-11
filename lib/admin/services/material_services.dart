// // services/material_api_service.dart
// import 'dart:convert';
// import 'package:ecoteam_app/admin/Screens/all_material_page.dart';
// import 'package:http/http.dart' as http;

// class MaterialApiService {
//   static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
//   // Add your authorization token here
//   static String? authToken;

//   static Future<Map<String, String>> getHeaders() async {
//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (authToken != null) 'Authorization': 'Bearer $authToken',
//     };
//   }

//   static Future<List<MaterialItem>> getMaterials() async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/materials'),
//         headers: await getHeaders(),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['status'] == 1) {
//           final List<dynamic> data = responseData['data']['data'];
//           return data.map((item) => MaterialItem.fromJson(item)).toList();
//         } else {
//           throw Exception('API returned error status');
//         }
//       } else {
//         throw Exception('Failed to load materials: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load materials: $e');
//     }
//   }

//   static Future<MaterialItem> addMaterial(MaterialItem material) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/materials'),
//         headers: await getHeaders(),
//         body: json.encode(material.toJson()),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         return MaterialItem.fromJson(responseData['data']);
//       } else {
//         throw Exception('Failed to add material: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to add material: $e');
//     }
//   }

//   static Future<MaterialItem> updateMaterial(MaterialItem material) async {
//     try {
//       final response = await http.put(
//         Uri.parse('$baseUrl/materials/${material.id}'),
//         headers: await getHeaders(),
//         body: json.encode(material.toJson()),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         return MaterialItem.fromJson(responseData['data']);
//       } else {
//         throw Exception('Failed to update material: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to update material: $e');
//     }
//   }

//   static Future<bool> deleteMaterial(int materialId) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/materials/$materialId'),
//         headers: await getHeaders(),
//       );

//       return response.statusCode == 200;
//     } catch (e) {
//       throw Exception('Failed to delete material: $e');
//     }
//   }
// }