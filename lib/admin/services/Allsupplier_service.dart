import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class SupplierApiService {
  // Endpoints using DioService base URL (https://app.ecoteamsolar.com/api)
  static const String suppliersEndpoint = '/suppliers';
  static const String categoriesEndpoint = '/supplier-categories';

  // GET - Get all suppliers
  static Future<List<Supplier>> getSuppliers({int? workspaceId, String? siteId}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (workspaceId != null) queryParameters['workspace_id'] = workspaceId;
      if (siteId != null && siteId.isNotEmpty) queryParameters['site_id'] = siteId;

      print('Fetching suppliers with params: $queryParameters');

      final response = await DioService.instance.dio.get(
        suppliersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 1 || responseData['status'] == 'success') {
          final List<dynamic> suppliersData = responseData['data'];
          return suppliersData.map((json) => Supplier.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load suppliers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Get supplier by ID
  static Future<Supplier> getSupplierById(int id) async {
    try {
      final response = await DioService.instance.dio.get('$suppliersEndpoint/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // GET - Get all supplier categories
  static Future<List<SupplierCategory>> getSupplierCategories() async {
    try {
      final response = await DioService.instance.dio.get(categoriesEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          final List<dynamic> categoriesData = responseData['data'];
          return categoriesData.map((json) => SupplierCategory.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load supplier categories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST - Create new supplier
  static Future<Supplier> addSupplier(Supplier supplier, {File? screenshot}) async {
    try {
      final formData = FormData();

      // Add fields from supplier model
      final supplierData = supplier.toJson();
      supplierData.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add screenshot if available
      if (screenshot != null) {
        formData.files.add(MapEntry(
          'upi_screenshot_1',
          await MultipartFile.fromFile(screenshot.path),
        ));
      }

      final response = await DioService.instance.dio.post(
        suppliersEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to add supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT - Update supplier
  static Future<Supplier> updateSupplier(Supplier supplier) async {
    try {
      final response = await DioService.instance.dio.put(
        '$suppliersEndpoint/${supplier.id}',
        data: supplier.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 1) {
          return Supplier.fromJson(responseData['data']);
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to update supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE - Delete supplier
  static Future<void> deleteSupplier(int id) async {
    try {
      final response = await DioService.instance.dio.delete('$suppliersEndpoint/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Status might be 1 (success)
        if (responseData['status'] != 1) {
           // Some APIs might return success message even if status != 1? 
           // Stick closer to original logic:
           throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to delete supplier. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}