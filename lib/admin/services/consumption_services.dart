import 'package:ecoteam_app/admin/models/consumptionLog_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class ConsumptionService {
  // Base URL handled by DioService
  
  // Fetch all consumptions
  Future<List<Consumption>> getConsumptions() async {
    try {
      final response = await DioService.instance.dio.get('/daily-consumptions');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;
        return _parseApiResponse(responseData);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading data: $e');
    }
  }

  // Fetch form creation data
  Future<Map<String, dynamic>> fetchCreateData() async {
    try {
      final response = await DioService.instance.dio.post(
        '/daily-consumptions/create-data',
        data: {"site_id": 0, "workspace_id": 0},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load form data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading form data: $e');
    }
  }

  // Create consumption
  Future<dynamic> createConsumption(Map<String, dynamic> requestBody) async {
    try {
      final response = await DioService.instance.dio.post(
        '/daily-consumptions',
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to add consumption: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding consumption: $e');
    }
  }

  // Update consumption
  Future<dynamic> updateConsumption(int id, Map<String, dynamic> requestBody) async {
    try {
      final response = await DioService.instance.dio.put(
        '/daily-consumptions/$id',
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.data;
      } else {
        throw Exception('Failed to update consumption: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating consumption: $e');
    }
  }

  // Delete consumption
  Future<void> deleteConsumption(int id) async {
    try {
      final response = await DioService.instance.dio.delete(
        '/daily-consumptions/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete consumption: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting consumption: $e');
    }
  }

  // Helper parsing method (copied from screen)
  List<Consumption> _parseApiResponse(List<dynamic> apiData) {
    return apiData.map((item) {
      final consumptionType = item['consumption_type']?.toString() ?? '';
      final machineryType = item['machinery_type']?.toString() ?? '';
      final siteData = item['site'] is Map ? item['site'] : {};

      List<ConsumptionItem> items = [];
      if (item['details'] is List) {
        items = (item['details'] as List).map((detail) {
          final materialData = detail['material'] is Map ? detail['material'] : {};
          return ConsumptionItem(
            material: materialData['name']?.toString() ?? 'Unknown Material',
            quantity: double.tryParse(detail['quantity']?.toString() ?? '0') ?? 0,
            unit: detail['unit']?.toString() ?? 'unit',
            price: double.tryParse(materialData['price']?.toString() ?? '0') ?? 0,
            materialId: detail['material_id'] != null
                ? int.tryParse(detail['material_id'].toString())
                : null,
          );
        }).toList();
      }

      final machineryData = item['machinery'] is Map ? item['machinery'] : {};

      return Consumption(
        id: item['id'] ?? 0,
        consumptionNo: item['consumption_number']?.toString() ?? 'N/A',
        consumptionDate: _parseDate(item['consumption_date']?.toString()),
        consumptionType: consumptionType,
        site: siteData['name']?.toString() ?? 'Unknown Site',
        consumptionFile: item['consumption_file']?.toString() ?? 'N/A',
        remarks: item['remarks']?.toString(),
        items: items.isNotEmpty ? items : null,
        machineryType: machineryType.isNotEmpty ? machineryType : null,
        machinery: machineryData['name']?.toString(),
        siteId: item['site_id']?.toString(),
        machineryId: item['machinery_id'] != null
            ? int.tryParse(item['machinery_id'].toString())
            : null,
        activityId: item['activity_id'] != null
            ? int.tryParse(item['activity_id'].toString())
            : null,
      );
    }).toList();
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
}
