
import 'dart:convert';
import 'dart:io';

import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_model.dart';
import 'package:http/http.dart' as http;

class ApiServicePurchaseInvoice {
  static const String baseUrl = 'http://sitepilot.easy2it.in/api';

  // Updated endpoints based on your API structure
  static const String getInvoicesEndpoint = '$baseUrl/purchase-invoice';
  static const String createInvoiceEndpoint = '$baseUrl/purchase-invoice';
  static const String updateInvoiceEndpoint = '$baseUrl/purchase-invoice';
  static const String getSuppliersEndpoint = '$baseUrl/suppliers';
  static const String getSitesEndpoint = '$baseUrl/projects';
  static const String getMaterialsEndpoint =
      '$baseUrl/purchase-invoice/create-data';
  static const String getUnitsEndpoint = '$baseUrl/units';

  static Future<List<Supplier>> getSuppliers() async {
    try {
      print('Fetching suppliers from: $getSuppliersEndpoint');
      final response = await http.get(
        Uri.parse(getSuppliersEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Suppliers response status: ${response.statusCode}');
      print('Suppliers response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

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

        // Remove duplicates by converting to set and back to list
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

  static Future<List<PurchaseInvoice>> getInvoices() async {
    try {
      print('Fetching invoices from: $getInvoicesEndpoint');
      final response = await http.get(
        Uri.parse(getInvoicesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

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
          'Failed to load invoices: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error loading invoices: $e');
      throw Exception('Failed to load invoices: $e');
    }
  }

  static Future<List<SiteModel>> getSites() async {
    try {
      print('Fetching sites from: $getSitesEndpoint');
      final response = await http.get(
        Uri.parse(getSitesEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Sites response status: ${response.statusCode}');
      print('Sites response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

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
      print('Error loading sites: $e');
      throw Exception('Failed to load sites: $e');
    }
  }

  static Future<List<MaterialModel>> getMaterials() async {
    try {
      print('Fetching materials from: $getMaterialsEndpoint');
      final response = await http.post(
        Uri.parse(getMaterialsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'site_id': 0, 'workspace_id': 0}),
      );

      print('Materials response status: ${response.statusCode}');
      print('Materials response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Materials API Response: $responseData');

        List<MaterialModel> materialsList = [];

        // Handle the nested materials structure from your API
        if (responseData is Map && responseData.containsKey('materials')) {
          final materialsMap = responseData['materials'];

          if (materialsMap is Map) {
            // Convert the map of materials to a list
            materialsMap.forEach((key, materialData) {
              if (materialData is Map) {
                try {
                  // Create a proper material object from the nested data
                  final material = MaterialModel(
                    id: int.tryParse(key) ?? 0,
                    name: materialData['name'] ?? '',
                    sku: materialData['sku'] ?? '',
                    categoryId: materialData['category_id'] ?? 0,
                    unitId: materialData['unit_id'] ?? 0,
                    description: materialData['description'] ?? '',
                    price:
                        double.tryParse(
                          materialData['price']?.toString() ?? '0',
                        ) ??
                        0.0,
                    reorderLevel: materialData['reorder_level'] ?? 0,
                    status: materialData['status'] ?? 'active',
                    image: materialData['image'],
                    siteId: materialData['site_id'],
                    createdBy: materialData['created_by'] ?? 0,
                    workspaceId: materialData['workspace_id'] ?? 0,
                    createdAt: materialData['created_at'] ?? '',
                    updatedAt: materialData['updated_at'] ?? '',
                    unit: materialData['unit'] != null
                        ? UnitModel.fromJson(materialData['unit'])
                        : null,
                  );
                  materialsList.add(material);
                } catch (e) {
                  print('Error parsing material $key: $e');
                }
              }
            });
          }
        }

        print('Extracted materials list length: ${materialsList.length}');

        if (materialsList.isEmpty) {
          print('No materials found in response');
          return [];
        }

        // Remove duplicates by ID
        final uniqueMaterials = materialsList.toSet().toList();

        print('Successfully parsed ${uniqueMaterials.length} materials');
        return uniqueMaterials;
      } else {
        throw Exception(
          'Failed to load materials: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error loading materials: $e');
      throw Exception('Failed to load materials: $e');
    }
  }

  static Future<List<UnitModel>> getUnits() async {
    try {
      print('Fetching units from: $getUnitsEndpoint');
      final response = await http.get(
        Uri.parse(getUnitsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Units response status: ${response.statusCode}');
      print('Units response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

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
          'Failed to load units: ${response.statusCode} - ${response.body}',
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

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(createInvoiceEndpoint),
      );

      // Add text fields based on your API structure
      request.fields['supplier_invoice_number'] =
          data['supplier_invoice_number'];
      request.fields['supplier_id'] = data['supplier_id'];
      request.fields['invoice_number'] = data['invoice_number'];
      request.fields['invoice_date'] = data['invoice_date'];
      request.fields['total_amount'] = data['total_amount'];
      request.fields['site_id'] = data['site_id'];
      request.fields['created_by'] = data['created_by'];
      request.fields['workspace_id'] = data['workspace_id'];
      request.fields['invoice_type'] = data['invoice_type']; // Added invoice type
      request.fields['method'] = 'PJT'; // Based on your API example

      // Add items only if invoice type is general_po
      if (data['invoice_type'] == 'general_po' && data['items'] != null) {
        for (int i = 0; i < (data['items'] as List).length; i++) {
          final item = data['items'][i];
          request.fields['items[$i][material_id]'] = item['material_id'];
          request.fields['items[$i][quantity]'] = item['quantity'];
          request.fields['items[$i][unit]'] = item['unit'];
          request.fields['items[$i][price]'] = item['price'];
          request.fields['items[$i][subtotal]'] = item['subtotal'];
        }
      }

      // Add file if exists
      if (data['invoice_file'] != null && data['invoice_file'] is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'invoice_file',
            data['invoice_file'].path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create response status: ${response.statusCode}');
      print('Create response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

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
          'Failed to create invoice: ${response.statusCode} - ${response.body}',
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

      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Add text fields
      request.fields['supplier_invoice_number'] =
          data['supplier_invoice_number'];
      request.fields['supplier_id'] = data['supplier_id'];
      request.fields['invoice_number'] = data['invoice_number'];
      request.fields['invoice_date'] = data['invoice_date'];
      request.fields['total_amount'] = data['total_amount'];
      request.fields['site_id'] = data['site_id'];
      request.fields['created_by'] = data['created_by'];
      request.fields['workspace_id'] = data['workspace_id'];
      request.fields['invoice_type'] = data['invoice_type']; // Added invoice type
      request.fields['method'] = 'PJT';
      request.fields['_method'] = 'PUT'; // For Laravel PUT method

      // Add items only if invoice type is general_po
      if (data['invoice_type'] == 'general_po' && data['items'] != null) {
        for (int i = 0; i < (data['items'] as List).length; i++) {
          final item = data['items'][i];
          request.fields['items[$i][material_id]'] = item['material_id'];
          request.fields['items[$i][quantity]'] = item['quantity'];
          request.fields['items[$i][unit]'] = item['unit'];
          request.fields['items[$i][price]'] = item['price'];
          request.fields['items[$i][subtotal]'] = item['subtotal'];
        }
      }

      // Add file if exists
      if (data['invoice_file'] != null && data['invoice_file'] is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'invoice_file',
            data['invoice_file'].path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

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
          'Failed to update invoice: ${response.statusCode} - ${response.body}',
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

      final response = await http.delete(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete invoice: ${response.statusCode} - ${response.body}',
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
    
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

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
        'Failed to load invoices for site $siteId: ${response.statusCode} - ${response.body}',
      );
    }
  } catch (e) {
    print('Error loading invoices for site $siteId: $e');
    throw Exception('Failed to load invoices for site $siteId: $e');
  }
}
}
