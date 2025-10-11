import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/unit_model.dart';

class UnitProvider extends ChangeNotifier {
  final String baseUrl = 'http://sitepilot.easy2it.in/api/units';

  List<Unit> _units = [];
  List<Unit> get units => _units;

  List<Unit> get filteredUnits => _units
      .where((unit) =>
          unit.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          unit.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Add Unit - FIXED with proper field mapping
  Future<void> addUnit(Unit unit) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Use the exact field names that the API expects based on your API documentation
      final Map<String, dynamic> unitData = unit.toCreateJson();

      print('Sending unit data: $unitData');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(unitData),
      );

      print('Add Unit - Status: ${response.statusCode}');
      print('Add Unit - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 1) {
          // Success - add the new unit to local list
          final Unit newUnit = Unit.fromJson(responseData['data'] ?? responseData);
          _units.add(newUnit);
          _errorMessage = '';
          notifyListeners();
        } else {
          // API returned error status
          _errorMessage = responseData['message'] ?? 'Failed to add unit: API returned error status';
          throw Exception(_errorMessage);
        }
      } else if (response.statusCode == 422) {
        // Handle validation errors
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Validation failed: Please check all required fields';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Failed to add unit: ${response.statusCode} - ${response.body}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Add Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Units - IMPROVED with better error handling
  Future<void> fetchUnits() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Fetch Units - Status: ${response.statusCode}');
      print('Fetch Units - Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 1) {
          if (responseData['data'] is List) {
            _units = (responseData['data'] as List)
                .map((e) => Unit.fromJson(e))
                .toList();
            _errorMessage = '';
          } else {
            _errorMessage = 'Invalid data format in API response';
            throw Exception(_errorMessage);
          }
        } else {
          _errorMessage = responseData['message'] ?? 'API returned error status';
          throw Exception(_errorMessage);
        }
      } else {
        _errorMessage = 'Failed to load units: ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Fetch Units Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh
  Future<void> refreshUnits() async {
    await fetchUnits();
  }

  // Update Unit - FIXED
  Future<void> updateUnit(Unit unit) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> unitData = unit.toUpdateJson();

      print('Updating unit ID: ${unit.id} with data: $unitData');

      final response = await http.put(
        Uri.parse('$baseUrl/${unit.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(unitData),
      );

      print('Update Unit - Status: ${response.statusCode}');
      print('Update Unit - Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 1) {
          // Update local unit
          final int index = _units.indexWhere((u) => u.id == unit.id);
          if (index != -1) {
            _units[index] = Unit.fromJson(responseData['data'] ?? responseData);
          }
          _errorMessage = '';
          notifyListeners();
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to update unit: API error';
          throw Exception(_errorMessage);
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Validation failed: Please check all required fields';
        throw Exception(_errorMessage);
      } else {
        _errorMessage = 'Failed to update unit: ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Update Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Unit - IMPROVED
  Future<void> deleteUnit(dynamic id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final String unitId = id.toString();
      
      print('Deleting unit ID: $unitId');

      final response = await http.delete(
        Uri.parse('$baseUrl/$unitId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Delete Unit - Status: ${response.statusCode}');
      print('Delete Unit - Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 1) {
          // Remove from local list
          _units.removeWhere((u) => u.id.toString() == unitId);
          _errorMessage = '';
          notifyListeners();
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to delete unit: API error';
          throw Exception(_errorMessage);
        }
      } else if (response.statusCode == 404) {
        _errorMessage = 'Unit not found';
        throw Exception(_errorMessage);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Failed to delete unit: ${response.statusCode}';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Delete Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get unit by ID
  Unit? getUnitById(dynamic id) {
    try {
      return _units.firstWhere((unit) => unit.id.toString() == id.toString());
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}