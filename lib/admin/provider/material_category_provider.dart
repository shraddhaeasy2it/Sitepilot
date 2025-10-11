// provider/material_category_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/material_category_model.dart';

class MaterialCategoryProvider with ChangeNotifier {
  List<MaterialCategory> _categories = [];
  List<MaterialCategory> _filteredCategories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _error = '';

  List<MaterialCategory> get categories => _categories;
  List<MaterialCategory> get filteredCategories => _filteredCategories;
  bool get isLoading => _isLoading;
  String get error => _error;

  static const String baseUrl = 'http://sitepilot.easy2it.in/api/material-categories';

  MaterialCategoryProvider() {
    fetchCategories();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterCategories();
    notifyListeners();
  }

  void _filterCategories() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('data') && responseData['data'] is List) {
          _categories = (responseData['data'] as List)
              .map((item) => MaterialCategory.fromJson(item))
              .toList();
          _filterCategories();
          _error = '';
        } else {
          _error = 'Invalid API response format: No data array found';
        }
      } else {
        _error = 'Failed to load categories: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Create minimal data with only required fields
      final Map<String, dynamic> categoryData = {
        'name': name,
        'is_active': 1,
        'site_id': null,
        'created_by': 1,
        'workspace_id': 1,
        'status': '0',
      };

      print('Sending data to API: $categoryData');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(categoryData),
      );

      print('Add Category Response Status: ${response.statusCode}');
      print('Add Category Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the list after successful addition
        await fetchCategories();
        _error = '';
      } else {
        _error = 'Failed to add category: ${response.statusCode} - ${response.body}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCategory(MaterialCategory category) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final Map<String, dynamic> categoryData = {
        'name': category.name,
        'is_active': category.isActive,
        'site_id': category.siteId,
        'created_by': category.createdBy,
        'workspace_id': category.workingNoId,
        'status': category.status,
      };

      print('Updating category ID: ${category.id}');
      print('Update data: $categoryData');

      final response = await http.put(
        Uri.parse('$baseUrl/${category.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(categoryData),
      );

      print('Update Category Response Status: ${response.statusCode}');
      print('Update Category Response Body: ${response.body}');

      if (response.statusCode == 200) {
        await fetchCategories();
        _error = '';
      } else {
        _error = 'Failed to update category: ${response.statusCode} - ${response.body}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      print('Deleting category ID: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Delete Category Response Status: ${response.statusCode}');
      print('Delete Category Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Remove from local list immediately
        _categories.removeWhere((category) => category.id == id);
        _filterCategories();
        _error = '';
        notifyListeners();
      } else {
        _error = 'Failed to delete category: ${response.statusCode} - ${response.body}';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCategories() async {
    await fetchCategories();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}