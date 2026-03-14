import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:ecoteam_app/admin/models/purchase_order_model.dart';
import 'package:ecoteam_app/contractor/models/site_model.dart';
import 'package:ecoteam_app/contractor/services/dio_service.dart';
import 'package:ecoteam_app/admin/models/unit_model.dart';
import 'package:ecoteam_app/admin/models/indent_model.dart';


class ApiServicePurchaseInvoice {
  // Endpoints (Relative paths for DioService)
  static const String getInvoicesEndpoint = '/purchase-invoice';
  static const String createInvoiceEndpoint = '/purchase-invoice';
  static const String updateInvoiceEndpoint = '/purchase-invoice';
  static const String getSuppliersEndpoint = '/suppliers';
  static const String getSitesEndpoint = '/projects';
  static const String getMaterialsEndpoint = '/purchase-invoice/create-data';
  static const String getUnitsEndpoint = '/units';
  static const String getPurchaseOrdersEndpoint = '/purchase-orders';
  static const String getPOCreateDataEndpoint = '/purchase-orders/create-data';

  static Future<List<Supplier>> getSuppliers() async {
    try {
      print('Fetching suppliers from: $getSuppliersEndpoint');
      final response = await DioService.instance.dio.get(getSuppliersEndpoint);

      print('Suppliers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> suppliersList;
        if (responseData is List) {
          suppliersList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          suppliersList = responseData['data'];
        } else if (responseData is Map &&
            responseData.containsKey('suppliers')) {
          suppliersList = responseData['suppliers'];
        } else {
          suppliersList = [responseData];
        }

        // Remove duplicates
        final uniqueSuppliers = suppliersList
            .map((json) => Supplier.fromJson(json))
            .toSet()
            .toList();
        return uniqueSuppliers;
      } else {
        throw Exception('Failed to load suppliers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading suppliers: $e');
      throw Exception('Failed to load suppliers: $e');
    }
  }

  static Future<List<PurchaseInvoice>> getInvoices({int? workspaceId, int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      print('Fetching invoices from: $getInvoicesEndpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(getInvoicesEndpoint, queryParameters: queryParams);

      print('Response status: ${response.statusCode}');
      print('Purchase Invoice API Response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> invoicesList;
        if (responseData is List) {
          invoicesList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          invoicesList = responseData['data'];
        } else if (responseData is Map &&
            responseData.containsKey('invoices')) {
          invoicesList = responseData['invoices'];
        } else {
          invoicesList = [responseData];
        }

        return invoicesList
            .map((json) => PurchaseInvoice.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to load invoices: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading invoices: $e');
      throw Exception('Failed to load invoices: $e');
    }
  }

  static Future<List<SiteModel>> getSites({int? workspaceId}) async {
    try {
      final queryParams = <String, dynamic>{
        'site_id': 0,
      };
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;

      print('Fetching sites from: $getSitesEndpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(getSitesEndpoint, queryParameters: queryParams);

      print('Sites response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> sitesList;
        if (responseData is List) {
          sitesList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          sitesList = responseData['data'];
        } else if (responseData is Map && responseData.containsKey('sites')) {
          sitesList = responseData['sites'];
        } else if (responseData is Map &&
            responseData.containsKey('projects')) {
          sitesList = responseData['projects'];
        } else {
          sitesList = [responseData];
        }

        // Remove duplicates
        final uniqueSites = sitesList
            .map((json) => SiteModel.fromJson(json))
            .toSet()
            .toList();
        return uniqueSites;
      } else {
        throw Exception('Failed to load sites: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Error loading sites Dio details: ${e.response?.data}');
      }
      print('Error loading sites: $e');
      throw Exception('Failed to load sites: $e');
    }
  }

  static Future<Map<String, dynamic>> getCreateData({
    required int siteId,
    required int workspaceId,
  }) async {
    try {
      print('Fetching create data from: $getMaterialsEndpoint with siteId: $siteId, workspaceId: $workspaceId');
      final response = await DioService.instance.dio.post(
        getMaterialsEndpoint,
        data: {'site_id': siteId, 'workspace_id': workspaceId},
      );

      print('Create Data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        // print('Create Data API Response: $responseData'); 

        List<MaterialModel> materialsList = [];
        List<Supplier> suppliersList = [];
        List<SiteModel> sitesList = [];
        String nextInvoiceNumber = '';

        // 1. Parse Materials (Existing logic)
        if (responseData is Map && responseData.containsKey('materials')) {
          final materialsData = responseData['materials'];
          if (materialsData is List) {
             materialsList = materialsData.map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e))).toList();
          } else if (materialsData is Map) {
            materialsData.forEach((key, materialData) {
              if (materialData is Map) {
                try {
                  materialsList.add(MaterialModel.fromJson(Map<String, dynamic>.from(materialData)));
                } catch (e) {
                  print('Error parsing material $key: $e');
                }
              }
            });
          }
        }

        // 2. Parse Stock Data (New logic)
        if (responseData is Map && (responseData.containsKey('stockData') || responseData.containsKey('Stock_Data'))) {
            final stockData = responseData['stockData'] ?? responseData['Stock_Data'];
            if (stockData is List) {
                final stockMaterials = stockData.map((item) {
                    final map = Map<String, dynamic>.from(item);
                    return MaterialModel(
                        id: int.tryParse(map['material_id']?.toString() ?? '0') ?? 0,
                        name: map['material_name']?.toString() ?? '',
                        sku: '', 
                        categoryId: 0, 
                        unitId: 0, 
                        description: '',
                        price: double.tryParse(map['material_price']?.toString() ?? '0') ?? 0.0,
                        reorderLevel: int.tryParse(map['reorder_level']?.toString() ?? '0') ?? 0,
                        status: 'active',
                        image: null,
                        createdBy: 0,
                        workspaceId: workspaceId,
                        createdAt: '',
                        updatedAt: '',
                        unit: UnitModel(
                            id: 0, 
                            name: map['unit_name']?.toString() ?? '', 
                            symbol: map['unit_symbol']?.toString() ?? '', 
                            isActive: 1, 
                            createdBy: 0, 
                            workspaceId: workspaceId, 
                            status: 'active', 
                            createdAt: '', 
                            updatedAt: ''
                        )
                    );
                }).toList();
                
                if (stockMaterials.isNotEmpty) {
                    materialsList = stockMaterials;
                }
            }
        }

        // 3. Parse Suppliers
        if (responseData is Map && responseData.containsKey('suppliers')) {
           final suppliersData = responseData['suppliers'];
           if (suppliersData is List) {
              suppliersList = suppliersData.map((e) => Supplier.fromJson(Map<String, dynamic>.from(e))).toList();
           } else if (suppliersData is Map && suppliersData.containsKey('data')) {
              if (suppliersData['data'] is List) {
                 suppliersList = (suppliersData['data'] as List).map((e) => Supplier.fromJson(Map<String, dynamic>.from(e))).toList();
              }
           }
        }

        // 4. Parse Sites
        if (responseData is Map && responseData.containsKey('sites')) {
           final sitesData = responseData['sites'];
           if (sitesData is List) {
              sitesList = sitesData.map((e) => SiteModel.fromJson(Map<String, dynamic>.from(e))).toList();
           }
        }
        
        // 5. Parse Next Invoice Number
        if (responseData is Map && responseData.containsKey('next_invoice_number')) {
            nextInvoiceNumber = responseData['next_invoice_number']?.toString() ?? '';
        }

        return {
          'materials': materialsList,
          'suppliers': suppliersList,
          'sites': sitesList,
          'next_invoice_number': nextInvoiceNumber,
        };
      } else {
        throw Exception(
          'Failed to load create data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading create data: $e');
      throw Exception('Failed to load create data: $e');
    }
  }

  static Future<List<UnitModel>> getUnits() async {
    try {
      print('Fetching units from: $getUnitsEndpoint');
      final response = await DioService.instance.dio.get(getUnitsEndpoint);

      print('Units response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> unitsList = [];

        if (responseData is Map && responseData.containsKey('data')) {
          unitsList = responseData['data'] ?? [];
        } else if (responseData is List) {
          unitsList = responseData;
        } else if (responseData is Map && responseData.containsKey('units')) {
          unitsList = responseData['units'] ?? [];
        }

        // Remove duplicates
        final uniqueUnits = unitsList
            .map((json) => UnitModel.fromJson(json))
            .toSet()
            .toList();
        return uniqueUnits;
      } else {
        throw Exception(
          'Failed to load units: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error loading units: $e');
      throw Exception('Failed to load units: $e');
    }
  }

  static Future<PurchaseInvoice> createInvoice(
    Map<String, dynamic> data,
  ) async {
    try {
      print('Creating invoice at: $createInvoiceEndpoint');
      print('Request data: $data');

      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('supplier_invoice_number', data['supplier_invoice_number'].toString()),
        MapEntry('supplier_id', data['supplier_id'].toString()),
        MapEntry('invoice_number', data['invoice_number'].toString()),
        MapEntry('invoice_date', data['invoice_date'].toString()),
        MapEntry('total_amount', data['total_amount'].toString()),
        MapEntry('site_id', data['site_id'].toString()),
        MapEntry('created_by', data['created_by'].toString()),
        MapEntry('workspace_id', data['workspace_id'].toString()),
        MapEntry('invoice_type', data['invoice_type'].toString()),
        MapEntry('method', 'PJT'),
      ]);

      // Add items only if invoice type is general_po
      if (data['invoice_type'] == 'general_po' && data['items'] != null) {
        final items = data['items'] as List;
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          formData.fields.addAll([
             MapEntry('items[$i][material_id]', item['material_id'].toString()),
             MapEntry('items[$i][quantity]', item['quantity'].toString()),
             MapEntry('items[$i][unit]', item['unit'].toString()),
             MapEntry('items[$i][price]', item['price'].toString()),
             MapEntry('items[$i][subtotal]', item['subtotal'].toString()),
          ]);
        }
      }

      // Add file if exists
      if (data['invoice_file'] != null && data['invoice_file'] is File) {
        formData.files.add(MapEntry(
          'invoice_file',
          await MultipartFile.fromFile(
            data['invoice_file'].path,
            filename: data['invoice_file'].path.split('/').last,
          ),
        ));
      }

      final response = await DioService.instance.dio.post(
        createInvoiceEndpoint,
        data: formData,
      );

      print('Create response status: ${response.statusCode}');
      print('Create response body: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Handle different response structures
        Map<String, dynamic> invoiceData;
        if (responseData is Map && responseData.containsKey('data')) {
          invoiceData = responseData['data'];
        } else if (responseData is Map && responseData.containsKey('invoice')) {
          invoiceData = responseData['invoice'];
        } else {
          invoiceData = responseData;
        }

        print('Parsed invoice data: $invoiceData');

        return PurchaseInvoice.fromJson(invoiceData);
      } else {
        throw Exception(
          'Failed to create invoice: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating invoice: $e');
      throw Exception('Failed to create invoice: $e');
    }
  }

  static Future<PurchaseInvoice> updateInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final endpoint = '$updateInvoiceEndpoint/$id';
      print('Updating invoice at: $endpoint');
      print('Update data: $data');

      final formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry('supplier_invoice_number', data['supplier_invoice_number'].toString()),
        MapEntry('supplier_id', data['supplier_id'].toString()),
        MapEntry('invoice_number', data['invoice_number'].toString()),
        MapEntry('invoice_date', data['invoice_date'].toString()),
        MapEntry('total_amount', data['total_amount'].toString()),
        MapEntry('site_id', data['site_id'].toString()),
        MapEntry('created_by', data['created_by'].toString()),
        MapEntry('workspace_id', data['workspace_id'].toString()),
        MapEntry('invoice_type', data['invoice_type'].toString()),
        MapEntry('method', 'PJT'),
        MapEntry('_method', 'PUT'), // For Laravel PUT spoofing
      ]);

      // Add items only if invoice type is general_po
      if (data['invoice_type'] == 'general_po' && data['items'] != null) {
        final items = data['items'] as List;
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          formData.fields.addAll([
            MapEntry('items[$i][material_id]', item['material_id'].toString()),
            MapEntry('items[$i][quantity]', item['quantity'].toString()),
            MapEntry('items[$i][unit]', item['unit'].toString()),
            MapEntry('items[$i][price]', item['price'].toString()),
            MapEntry('items[$i][subtotal]', item['subtotal'].toString()),
          ]);
        }
      }

      // Add file if exists
      if (data['invoice_file'] != null && data['invoice_file'] is File) {
         formData.files.add(MapEntry(
          'invoice_file',
          await MultipartFile.fromFile(
            data['invoice_file'].path,
            filename: data['invoice_file'].path.split('/').last,
          ),
        ));
      }

      // Use POST with _method=PUT for Laravel when sending Multipart
      final response = await DioService.instance.dio.post(
        endpoint,
        data: formData,
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response structures
        Map<String, dynamic> invoiceData;
        if (responseData is Map && responseData.containsKey('data')) {
          invoiceData = responseData['data'];
        } else if (responseData is Map && responseData.containsKey('invoice')) {
          invoiceData = responseData['invoice'];
        } else {
          invoiceData = responseData;
        }

        return PurchaseInvoice.fromJson(invoiceData);
      } else {
        throw Exception(
          'Failed to update invoice: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating invoice: $e');
      throw Exception('Failed to update invoice: $e');
    }
  }

  static Future<void> deleteInvoice(int id) async {
    try {
      final endpoint = '$getInvoicesEndpoint/$id';
      print('Deleting invoice at: $endpoint');

      final response = await DioService.instance.dio.delete(endpoint);

      print('Delete response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete invoice: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting invoice: $e');
      throw Exception('Failed to delete invoice: $e');
    }
  }
  
  static Future<List<PurchaseInvoice>> getInvoicesBySiteId(int siteId) async {
  try {
    final endpoint = '$getInvoicesEndpoint?site_id=$siteId';
    print('Fetching invoices for site $siteId from: $endpoint');
    
    final response = await DioService.instance.dio.get(
      getInvoicesEndpoint, 
      queryParameters: {'site_id': siteId},
    );

    print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = response.data;

      List<dynamic> invoicesList;
      if (responseData is List) {
        invoicesList = responseData;
      } else if (responseData is Map && responseData.containsKey('data')) {
        invoicesList = responseData['data'];
      } else if (responseData is Map && responseData.containsKey('invoices')) {
        invoicesList = responseData['invoices'];
      } else {
        invoicesList = [responseData];
      }

      return invoicesList
          .map((json) => PurchaseInvoice.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to load invoices for site $siteId: ${response.statusCode}',
      );
    }
  } catch (e) {
    print('Error loading invoices for site $siteId: $e');
    throw Exception('Failed to load invoices for site $siteId: $e');
  }
}

  static Future<List<PurchaseOrderModel>> getPurchaseOrders({int? workspaceId, int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (workspaceId != null) queryParams['workspace_id'] = workspaceId;
      if (siteId != null) queryParams['site_id'] = siteId;

      print('Fetching purchase orders from: $getPurchaseOrdersEndpoint with params: $queryParams');
      final response = await DioService.instance.dio.get(getPurchaseOrdersEndpoint, queryParameters: queryParams);

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = response.data;

        List<dynamic> poList;
        if (responseData is List) {
          poList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          poList = responseData['data'];
        } else if (responseData is Map && responseData.containsKey('purchase_orders')) {
          poList = responseData['purchase_orders'];
        } else {
          poList = [responseData];
        }

        return poList.map((json) => PurchaseOrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load purchase orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading purchase orders: $e');
      throw Exception('Failed to load purchase orders: $e');
    }
  }

  static Future<void> deletePurchaseOrder(int id) async {
    try {
      final endpoint = '$getPurchaseOrdersEndpoint/$id';
      print('Deleting purchase order at: $endpoint');

      final response = await DioService.instance.dio.delete(endpoint);

      print('Delete response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete purchase order: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting purchase order: $e');
      throw Exception('Failed to delete purchase order: $e');
    }
  }

  static Future<Map<String, dynamic>> getPOCreateData({
    required int siteId,
    required int workspaceId,
  }) async {
    try {
      print('Fetching PO create data from: $getPOCreateDataEndpoint');
      final response = await DioService.instance.dio.post(
        getPOCreateDataEndpoint,
        data: {'site_id': siteId, 'workspace_id': workspaceId},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'];
          
          List<Supplier> suppliers = (data['suppliers'] as List?)
              ?.map((e) => Supplier.fromJson(e))
              .toList() ?? [];
              
          List<MaterialModel> materials = (data['materials'] as List?)
              ?.map((e) => MaterialModel.fromJson(e))
              .toList() ?? [];
              
          List<SiteModel> sites = (data['sites'] as List?)
              ?.map((e) => SiteModel.fromJson(e))
              .toList() ?? [];
              
          List<IndentModel> indents = (data['indents'] as List?)
              ?.map((e) => IndentModel.fromJson(e))
              .toList() ?? [];
              
          return {
            'suppliers': suppliers,
            'materials': materials,
            'sites': sites,
            'indents': indents,
            'gstMasters': data['gstMasters'] ?? [],
            'next_po_number': data['next_po_number'] ?? '',
          };
        }
      }
      return {
        'suppliers': [],
        'materials': [],
        'sites': [],
        'indents': [],
        'gstMasters': [],
      };
    } catch (e) {
      print('Error loading PO create data: $e');
      throw Exception('Failed to load PO create data: $e');
    }
  }

  static Future<PurchaseOrderModel> createPurchaseOrder(Map<String, dynamic> data, {File? referenceFile}) async {
    try {
      FormData formData = FormData.fromMap(data);
      if (referenceFile != null) {
        formData.files.add(MapEntry(
          'reference_file',
          await MultipartFile.fromFile(referenceFile.path),
        ));
      }
      
      print('Creating purchase order with: $data');
      final response = await DioService.instance.dio.post(getPurchaseOrdersEndpoint, data: formData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        return PurchaseOrderModel.fromJson(resData['data'] ?? resData);
      } else {
        throw Exception('Failed to create purchase order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating purchase order: $e');
      throw Exception('Failed to create purchase order: $e');
    }
  }

  static Future<PurchaseOrderModel> updatePurchaseOrder(int id, Map<String, dynamic> data, {File? referenceFile}) async {
    try {
      FormData formData = FormData.fromMap(data);
      formData.fields.add(const MapEntry('_method', 'PUT'));
      
      if (referenceFile != null) {
        formData.files.add(MapEntry(
          'reference_file',
          await MultipartFile.fromFile(referenceFile.path),
        ));
      }

      final endpoint = '$getPurchaseOrdersEndpoint/$id';
      print('Updating purchase order at $endpoint with: $data');
      final response = await DioService.instance.dio.post(endpoint, data: formData);
      
      if (response.statusCode == 200) {
        final resData = response.data;
        return PurchaseOrderModel.fromJson(resData['data'] ?? resData);
      } else {
        throw Exception('Failed to update purchase order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating purchase order: $e');
      throw Exception('Failed to update purchase order: $e');
    }
  }

  static Future<PurchaseOrderModel> updatePurchaseOrderStatus(int id, String status) async {
    try {
      final endpoint = '$getPurchaseOrdersEndpoint/$id/status';
      print('Updating purchase order status at $endpoint to $status');

      final response = await DioService.instance.dio.put(
        endpoint,
        queryParameters: {'status': status},
      );

      print('Update status response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        return PurchaseOrderModel.fromJson(resData['data'] ?? resData);
      } else {
        throw Exception('Failed to update purchase order status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating purchase order status: $e');
      throw Exception('Failed to update purchase order status: $e');
    }
  }
}
