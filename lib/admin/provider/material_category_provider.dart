// provider/material_category_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
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

  // Base URL is in DioService, endpoint here
  static const String endpoint = '/material-categories';

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
      final response = await DioService.instance.dio.get(endpoint);

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData is Map && responseData.containsKey('data') && responseData['data'] is List) {
          _categories = (responseData['data'] as List)
              .map((item) => MaterialCategory.fromJson(item))
              .toList();
          _filterCategories();
          _error = '';
        } else {
          _error = 'Invalid API response format: No data array found';
        }
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

  Future<void> addCategory(String name, {
    required int siteId,
    required int createdBy,
    required int workspaceId,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final Map<String, dynamic> categoryData = {
        'name': name,
        'is_active': 1,
        'site_id': siteId,
        'created_by': createdBy,
        'workspace_id': workspaceId,
        'status': '0',
      };

      print('Sending data to API: $categoryData');

      final response = await DioService.instance.dio.post(
        endpoint,
        data: categoryData,
      );

      print('Add Category Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          final newCategory = MaterialCategory.fromJson(responseData['data']);
          _categories.insert(0, newCategory);
          _filterCategories();
          _error = '';
        } else {
          await fetchCategories();
        }
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
        'site_id': category.siteId ?? 0,
        'created_by': category.createdBy,
        'workspace_id': category.workingNoId,
        'status': category.status,
      };

      print('Updating category ID: ${category.id}');
      print('Update data: $categoryData');

      final response = await DioService.instance.dio.put(
        '$endpoint/${category.id}',
        data: categoryData,
      );

      print('Update Category Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchCategories();
        _error = '';
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

      final response = await DioService.instance.dio.delete('$endpoint/$id');

      print('Delete Category Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _categories.removeWhere((category) => category.id == id);
        _filterCategories();
        _error = '';
        notifyListeners();
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
