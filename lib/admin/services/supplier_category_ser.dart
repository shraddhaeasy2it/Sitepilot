// services/supplier_category_service.dart
import 'dart:convert';
import 'package:ecoteam_app/admin/models/supplier_categary_model.dart';
import 'package:http/http.dart' as http;


class SupplierCategoryService {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';
  
  Future<SupplierCategoryResponse> getSupplierCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplier-categories'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return SupplierCategoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load supplier categories');
    }
  }

  Future<SupplierCategory> createSupplierCategory(SupplierCategory category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/supplier-categories'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(category.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return SupplierCategory.fromJson(data);
    } else {
      throw Exception('Failed to create supplier category');
    }
  }

  Future<SupplierCategory> updateSupplierCategory(SupplierCategory category) async {
    final response = await http.put(
      Uri.parse('$baseUrl/supplier-categories/${category.id}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(category.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return SupplierCategory.fromJson(data);
    } else {
      throw Exception('Failed to update supplier category');
    }
  }

  Future<void> deleteSupplierCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/supplier-categories/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete supplier category');
    }
  }
}