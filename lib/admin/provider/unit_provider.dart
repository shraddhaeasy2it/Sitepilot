import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import '../models/unit_model.dart';

class UnitProvider extends ChangeNotifier {
  // Base URL is handled in DioService
  final String endpoint = '/units';

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

  // Add Unit
  Future<void> addUnit(Unit unit) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> unitData = unit.toCreateJson();

      print('Sending unit data: $unitData');

      final response = await DioService.instance.dio.post(
        endpoint,
        data: unitData,
      );

      print('Add Unit - Status: ${response.statusCode}');
      print('Add Unit - Body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          final Unit newUnit = Unit.fromJson(responseData['data'] ?? responseData);
          _units.add(newUnit);
          _errorMessage = '';
          notifyListeners();
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to add unit: API returned error status';
          throw Exception(_errorMessage);
        }
      } 
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
         final errorData = e.response?.data;
         _errorMessage = errorData is Map ? (errorData['message'] ?? 'Validation failed') : 'Validation failed';
      } else {
         _errorMessage = 'Failed to add unit: ${e.message}';
      }
      print('Add Unit Error: $e');
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      print('Add Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Units
  Future<void> fetchUnits({int? workspaceId, int? siteId}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      print('Fetching units from: $endpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      
      print('Fetch Units - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        
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
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Fetch Units Error: $e');
      // rethrow; // Optional depending on how UI handles it
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh
  Future<void> refreshUnits() async {
    await fetchUnits();
  }

  // Update Unit
  Future<void> updateUnit(Unit unit) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> unitData = unit.toUpdateJson();

      print('Updating unit ID: ${unit.id} with data: $unitData');

      final response = await DioService.instance.dio.put(
        '$endpoint/${unit.id}',
        data: unitData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          final int index = _units.indexWhere((u) => u.id == unit.id);
          if (index != -1) {
            _units[index] = Unit.fromJson(responseData['data'] ?? responseData);
          }
          _errorMessage = '';
          notifyListeners();
        } else {
          _errorMessage = responseData['message'] ?? 'Failed to update unit';
          throw Exception(_errorMessage);
        }
      }
    } on DioException catch (e) {
       if (e.response?.statusCode == 422) {
         final errorData = e.response?.data;
         _errorMessage = errorData is Map ? (errorData['message'] ?? 'Validation failed') : 'Validation failed';
      } else {
         _errorMessage = 'Failed to update unit: ${e.message}';
      }
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      print('Update Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Unit
  Future<void> deleteUnit(dynamic id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final String unitId = id.toString();
      print('Deleting unit ID: $unitId');

      final response = await DioService.instance.dio.delete('$endpoint/$unitId');

      if (response.statusCode == 200) {
         final responseData = response.data;
         if (responseData['status'] == 1) {
            _units.removeWhere((u) => u.id.toString() == unitId);
            _errorMessage = '';
            notifyListeners();
         } else {
            _errorMessage = responseData['message'] ?? 'Failed to delete unit';
            throw Exception(_errorMessage);
         }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _errorMessage = 'Unit not found';
      } else {
         final errorData = e.response?.data;
         _errorMessage = errorData is Map ? (errorData['message'] ?? 'Delete failed') : 'Delete failed';
      }
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      print('Delete Unit Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Unit? getUnitById(dynamic id) {
    try {
      return _units.firstWhere((unit) => unit.id.toString() == id.toString());
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
