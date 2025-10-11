import 'package:flutter/material.dart';
import '../models/material_category_model.dart';

class MaterialCategoryProvider with ChangeNotifier {
  List<MaterialCategory> _categories = [
    MaterialCategory(
      id: '1',
      name: 'Exterior & Landscaping',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MaterialCategory(
      id: '2',
      name: '	Doors & Windows',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MaterialCategory(
      id: '3',
      name: '	Finishing Materials',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MaterialCategory(
      id: '4',
      name: '	Electrical Items',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MaterialCategory(
      id: '5',
      name: '	Plumbing Materials',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    MaterialCategory(
      id: '6',
      name: 'Tiles',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      updatedAt: DateTime.now(),
    ),
  ];

  bool _isLoading = false;
  String _searchQuery = '';

  List<MaterialCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<MaterialCategory> get filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> addCategory(MaterialCategory category) async {
    setLoading(true);
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newCategory = category.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _categories.insert(0, newCategory);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add category: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> updateCategory(MaterialCategory category) async {
    setLoading(true);
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    setLoading(true);
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      _categories.removeWhere((category) => category.id == categoryId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> refreshCategories() async {
    setLoading(true);
    try {
      // Simulate API call to refresh data
      await Future.delayed(const Duration(seconds: 1));
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to refresh categories: $e');
    } finally {
      setLoading(false);
    }
  }
}