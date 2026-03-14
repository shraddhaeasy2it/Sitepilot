import 'package:dio/dio.dart';
import 'package:ecoteam_app/contractor/models/stock_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';

class StockService {
  static final StockService _instance = StockService._internal();
  static StockService get instance => _instance;

  StockService._internal();

  Future<List<StockReportItem>> getStockReport(int siteId) async {
    try {
      final now = DateTime.now();
      final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final queryParams = {
        'site_id': siteId,
        'end_date': formattedDate,
        'material_id': 0, // Default to 0 for all materials
      };

      print('Fetching stock info from: /stock-reports-api with params: $queryParams');

      final response = await DioService.instance.dio.get(
        '/stock-reports-api',
        queryParameters: queryParams,
      );

      print('Stock API Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((item) => StockReportItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load stock report: $e');
    }
  }
}
