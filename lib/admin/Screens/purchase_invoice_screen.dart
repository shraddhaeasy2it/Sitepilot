import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PurchaseInvoice {
  final int id;
  final String invoiceNumber;
  final String invoiceDate;
  final String supplierInvoiceNumber;
  final int supplierId;
  final double totalAmount;
  final String status;
  final String? invoiceFile;
  final int siteId;
  final int createdBy;
  final int workspaceId;
  final String createdAt;
  final String updatedAt;
  final List<InvoiceItem>? items;
  final dynamic supplier;
  final dynamic site;

  PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.supplierInvoiceNumber,
    required this.supplierId,
    required this.totalAmount,
    required this.status,
    this.invoiceFile,
    required this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.supplier,
    this.site,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      id: json['id'] ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      invoiceDate: json['invoice_date'] ?? '',
      supplierInvoiceNumber: json['supplier_invoice_number'] ?? '',
      supplierId: json['supplier_id'] is int
          ? json['supplier_id']
          : int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      invoiceFile: json['invoice_file'],
      siteId: json['site_id'] is int
          ? json['site_id']
          : int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: json['workspace_id'] is int
          ? json['workspace_id']
          : int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => InvoiceItem.fromJson(item))
                .toList()
          : null,
      supplier: json['supplier'],
      site: json['site'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate,
      'supplier_invoice_number': supplierInvoiceNumber,
      'supplier_id': supplierId.toString(),
      'total_amount': totalAmount.toStringAsFixed(2),
      'site_id': siteId.toString(),
      'created_by': createdBy.toString(),
      'workspace_id': workspaceId.toString(),
    };
  }
}

class InvoiceItem {
  final int id;
  final int purchaseInvoiceId;
  final int materialId;
  final double quantity;
  final String unit;
  final double price;
  final double subtotal;
  final String createdAt;
  final String updatedAt;
  final dynamic material;

  InvoiceItem({
    required this.id,
    required this.purchaseInvoiceId,
    required this.materialId,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
    this.material,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? 0,
      purchaseInvoiceId: json['purchase_invoice_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      material: json['material'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId.toString(),
      'quantity': quantity.toString(),
      'unit': unit,
      'price': price.toStringAsFixed(2),
      'subtotal': subtotal.toStringAsFixed(2),
    };
  }
}

class MaterialModel {
  final int id;
  final String name;
  final String sku;
  final int categoryId;
  final int unitId;
  final String description;
  final double price;
  final int reorderLevel;
  final String status;
  final String? image;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String createdAt;
  final String updatedAt;
  final UnitModel? unit;

  MaterialModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.unitId,
    required this.description,
    required this.price,
    required this.reorderLevel,
    required this.status,
    this.image,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.unit,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['category_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      reorderLevel: json['reorder_level'] ?? 0,
      status: json['status'] ?? '',
      image: json['image'],
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      unit: json['unit'] != null ? UnitModel.fromJson(json['unit']) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UnitModel {
  final int id;
  final String name;
  final String symbol;
  final String? description;
  final int isActive;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String status;
  final String createdAt;
  final String updatedAt;

  UnitModel({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
    required this.isActive,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? 0,
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SupplierModel {
  final int id;
  final String name;
  final int categoryId;
  final String type;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final String? upiScreenshot1;
  final String? upiScreenshot2;
  final String gstNumber;
  final String panNumber;
  final String registrationNumber;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String paymentTerms;
  final int? siteId;
  final int workspaceId;
  final int createdBy;
  final int isActive;
  final String status;
  final String createdAt;
  final String updatedAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.type,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.country,
    this.upiScreenshot1,
    this.upiScreenshot2,
    required this.gstNumber,
    required this.panNumber,
    required this.registrationNumber,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.paymentTerms,
    this.siteId,
    required this.workspaceId,
    required this.createdBy,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      type: json['type'] ?? '',
      contactPerson: json['contact_person'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pinCode: json['pin_code'] ?? '',
      country: json['country'] ?? '',
      upiScreenshot1: json['upi_screenshot_1'],
      upiScreenshot2: json['upi_screenshot_2'],
      gstNumber: json['gst_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      paymentTerms: json['payment_terms'] ?? '',
      siteId: json['site_id'],
      workspaceId: json['workspace_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      isActive: json['is_active'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class SiteModel {
  final int id;
  final String name;
  final String status;
  final String? range;
  final String description;
  final String startDate;
  final String endDate;
  final double budget;
  final int isActive;
  final String type;
  final String currency;
  final String profileProgress;
  final String progress;
  final String taskProgress;
  final String? test;
  final double estimateSize;
  final String copylinksetting;
  final String? password;
  final int workspaceId;
  final int createdBy;
  final String createdAt;
  final String updatedAt;

  SiteModel({
    required this.id,
    required this.name,
    required this.status,
    this.range,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.isActive,
    required this.type,
    required this.currency,
    required this.profileProgress,
    required this.progress,
    required this.taskProgress,
    this.test,
    required this.estimateSize,
    required this.copylinksetting,
    this.password,
    required this.workspaceId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      range: json['range'],
      description: json['description'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      budget: double.tryParse(json['budget']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] ?? 0,
      type: json['type'] ?? '',
      currency: json['currency'] ?? '',
      profileProgress: json['profile_progress'] ?? '',
      progress: json['progress'] ?? '',
      taskProgress: json['task_progress'] ?? '',
      test: json['test'],
      estimateSize:
          double.tryParse(json['estimate_size']?.toString() ?? '0') ?? 0.0,
      copylinksetting: json['copylinksetting'] ?? '',
      password: json['password'],
      workspaceId: json['workspace_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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

  static Future<List<SupplierModel>> getSuppliers() async {
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
            .map((json) => SupplierModel.fromJson(json))
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
      request.fields['method'] = 'PJT'; // Based on your API example

      // Add items
      for (int i = 0; i < (data['items'] as List).length; i++) {
        final item = data['items'][i];
        request.fields['items[$i][material_id]'] = item['material_id'];
        request.fields['items[$i][quantity]'] = item['quantity'];
        request.fields['items[$i][unit]'] = item['unit'];
        request.fields['items[$i][price]'] = item['price'];
        request.fields['items[$i][subtotal]'] = item['subtotal'];
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
      request.fields['method'] = 'PJT';
      request.fields['_method'] = 'PUT'; // For Laravel PUT method

      // Add items
      for (int i = 0; i < (data['items'] as List).length; i++) {
        final item = data['items'][i];
        request.fields['items[$i][material_id]'] = item['material_id'];
        request.fields['items[$i][quantity]'] = item['quantity'];
        request.fields['items[$i][unit]'] = item['unit'];
        request.fields['items[$i][price]'] = item['price'];
        request.fields['items[$i][subtotal]'] = item['subtotal'];
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
}

class PurchaseInvoicesPage extends StatefulWidget {
  const PurchaseInvoicesPage({super.key});

  @override
  State<PurchaseInvoicesPage> createState() => _PurchaseInvoicesPageState();
}

class _PurchaseInvoicesPageState extends State<PurchaseInvoicesPage> {
  List<PurchaseInvoice> _invoices = [];
  List<SupplierModel> _suppliers = [];
  List<SiteModel> _sites = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final invoices = await ApiServicePurchaseInvoice.getInvoices();
    final suppliers = await ApiServicePurchaseInvoice.getSuppliers();
    final sites = await ApiServicePurchaseInvoice.getSites();

    setState(() {
      _invoices = invoices;
      _suppliers = suppliers;
      _sites = sites;
      _isLoading = false;
    });
    
    print('Loaded ${_invoices.length} invoices, ${_suppliers.length} suppliers, ${_sites.length} sites');
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
    });
    print('Error loading all data: $e');
  }
}

  List<PurchaseInvoice> get _filteredInvoices {
    if (_searchQuery.isEmpty) {
      return _invoices;
    }
    return _invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          invoice.supplierInvoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          _getSupplierName(
            invoice.supplierId,
          ).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getSiteName(
            invoice.siteId,
          ).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showAddInvoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceBottomSheet(
        suppliers: _suppliers,
        sites: _sites,
        onInvoiceSaved: () {
          // Refresh the data immediately after successful creation
          _loadAllData();
        },
      ),
    );
  }

  void _showEditInvoiceBottomSheet(PurchaseInvoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditInvoiceBottomSheet(
        invoice: invoice,
        suppliers: _suppliers,
        sites: _sites,
        onInvoiceSaved: _loadAllData,
      ),
    );
  }

  void _showDeleteInvoiceDialog(PurchaseInvoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ApiServicePurchaseInvoice.deleteInvoice(invoice.id);
                  // Remove from local list immediately for better UX
                  setState(() {
                    _invoices.removeWhere((inv) => inv.id == invoice.id);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invoice ${invoice.invoiceNumber} deleted successfully',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete invoice: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _getSiteName(int siteId) {
    try {
      final site = _sites.firstWhere((site) => site.id == siteId);
      return site.name;
    } catch (e) {
      print(
        'Site not found for id: $siteId, available sites: ${_sites.map((s) => '${s.id}: ${s.name}').toList()}',
      );
      return 'Unknown Site';
    }
  }

  String _getSupplierName(int supplierId) {
    try {
      final supplier = _suppliers.firstWhere(
        (supplier) => supplier.id == supplierId,
      );
      return supplier.name;
    } catch (e) {
      return 'Unknown Supplier';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Purchase Invoices',
          style: TextStyle(color: Colors.white),
        ),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4a63c0), Color(0xFF3a53b0), Color(0xFF2a43a0)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddInvoiceBottomSheet,
            tooltip: 'Add New Invoice',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAllData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search invoices...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Entry Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${_filteredInvoices.length} of ${_invoices.length} invoices',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Invoice Cards
                Expanded(
                  child: _invoices.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No invoices found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first invoice',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _filteredInvoices[index];
                            return InvoiceCard(
                              invoice: invoice,
                              getSiteName: _getSiteName,
                              getSupplierName: _getSupplierName,
                              onEdit: () =>
                                  _showEditInvoiceBottomSheet(invoice),
                              onDelete: () => _showDeleteInvoiceDialog(invoice),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;
  final String Function(int) getSiteName;
  final String Function(int) getSupplierName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.getSiteName,
    required this.getSupplierName,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2a43a0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: invoice.status == 'Cancelled'
                        ? Colors.red
                        : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    invoice.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(invoice.invoiceDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      color: const Color(0xFF2a43a0),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getSupplierName(invoice.supplierId),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  getSiteName(invoice.siteId),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (invoice.supplierInvoiceNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Supplier: ${invoice.supplierInvoiceNumber}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditInvoiceBottomSheet extends StatefulWidget {
  final PurchaseInvoice? invoice;
  final List<SupplierModel> suppliers;
  final List<SiteModel> sites;
  final VoidCallback? onInvoiceSaved;

  const AddEditInvoiceBottomSheet({
    super.key,
    this.invoice,
    required this.suppliers,
    required this.sites,
    this.onInvoiceSaved,
  });

  @override
  State<AddEditInvoiceBottomSheet> createState() =>
      _AddEditInvoiceBottomSheetState();
}

class _AddEditInvoiceBottomSheetState extends State<AddEditInvoiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _supplierInvoiceNoController =
      TextEditingController();
  final TextEditingController _invoiceDateController = TextEditingController();

  int? _selectedSiteId;
  int? _selectedSupplierId;
  final List<MaterialItem> _materialItems = [];
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  bool _isSubmitting = false;
  List<MaterialModel> _materials = [];
  List<UnitModel> _units = [];
  bool _isLoadingMaterials = false;

  @override
  void initState() {
    super.initState();
    _loadMaterialsAndUnits();

    if (widget.invoice != null) {
      // Edit mode - populate fields
      _invoiceNoController.text = widget.invoice!.invoiceNumber;
      _supplierInvoiceNoController.text = widget.invoice!.supplierInvoiceNumber;

      _selectedSiteId = widget.invoice!.siteId;
      _selectedSupplierId = widget.invoice!.supplierId;

      _invoiceDateController.text = _formatDateForDisplay(
        DateTime.parse(widget.invoice!.invoiceDate),
      );
      _selectedDate = DateTime.parse(widget.invoice!.invoiceDate);

      // Populate materials for edit mode
      if (widget.invoice!.items != null) {
        for (var item in widget.invoice!.items!) {
          String materialName = 'Material ${item.materialId}';
          String unitSymbol = item.unit;

          _materialItems.add(
            MaterialItem(
              materialId: item.materialId,
              materialName: materialName,
              quantity: item.quantity.toString(),
              unit: unitSymbol,
              price: item.price.toStringAsFixed(2),
              subtotal: item.subtotal.toStringAsFixed(2),
            ),
          );
        }
      }
    } else {
      // Add mode - set default values
      _invoiceNoController.text =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      _invoiceDateController.text = _formatDateForDisplay(DateTime.now());
      _selectedDate = DateTime.now();
      _selectedSupplierId = widget.suppliers.isNotEmpty
          ? widget.suppliers.first.id
          : null;
      _selectedSiteId = widget.sites.isNotEmpty ? widget.sites.first.id : null;

      // Add one empty material item for add mode
      _addMaterialItem();
    }
  }

  Future<void> _loadMaterialsAndUnits() async {
    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      final materials = await ApiServicePurchaseInvoice.getMaterials();
      final units = await ApiServicePurchaseInvoice.getUnits();

      setState(() {
        _materials = materials;
        _units = units;
        _isLoadingMaterials = false;
      });

      // If in edit mode and we have materials, update the material names
      if (widget.invoice != null && _materials.isNotEmpty) {
        for (int i = 0; i < _materialItems.length; i++) {
          final item = _materialItems[i];
          try {
            final material = _materials.firstWhere(
              (m) => m.id == item.materialId,
            );
            if (material.name != item.materialName) {
              setState(() {
                _materialItems[i] = MaterialItem(
                  materialId: item.materialId,
                  materialName: material.name,
                  quantity: item.quantity,
                  unit: item.unit,
                  price: item.price,
                  subtotal: item.subtotal,
                );
              });
            }
          } catch (e) {
            print('Material not found for id: ${item.materialId}');
          }
        }
      }

      print('Loaded ${_materials.length} materials and ${_units.length} units');
    } catch (e) {
      print('Error loading materials or units: $e');
      setState(() {
        _isLoadingMaterials = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load materials: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateForDisplay(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _invoiceDateController.text = _formatDateForDisplay(picked);
      });
    }
  }

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedFile = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedFile = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addMaterialItem() {
    setState(() {
      _materialItems.add(MaterialItem());
    });
  }

  void _updateMaterialItem(int index, MaterialItem updatedItem) {
    setState(() {
      _materialItems[index] = updatedItem;
    });
  }

  void _removeMaterialItem(int index) {
    setState(() {
      _materialItems.removeAt(index);
    });
  }

  double get _totalAmount {
    double total = 0;
    for (var item in _materialItems) {
      if (item.subtotal.isNotEmpty) {
        total += double.tryParse(item.subtotal) ?? 0;
      }
    }
    return total;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_materialItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one material item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSiteId == null || _selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select site and supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> invoiceData = {
        'invoice_number': _invoiceNoController.text,
        'invoice_date': _invoiceDateController.text,
        'supplier_invoice_number': _supplierInvoiceNoController.text,
        'supplier_id': _selectedSupplierId.toString(),
        'total_amount': _totalAmount.toStringAsFixed(2),
        'site_id': _selectedSiteId.toString(),
        'created_by': '1', // Assuming current user ID is 1
        'workspace_id': '1', // Assuming workspace ID is 1
        'invoice_file': _selectedFile,
        'items': _materialItems
            .where((item) => item.materialId > 0)
            .map(
              (item) => {
                'material_id': item.materialId.toString(),
                'quantity': item.quantity,
                'unit': item.unit,
                'price': item.price,
                'subtotal': item.subtotal,
              },
            )
            .toList(),
      };

      print('Submitting invoice data: $invoiceData');

      PurchaseInvoice result;
      if (widget.invoice != null) {
        result = await ApiServicePurchaseInvoice.updateInvoice(
          widget.invoice!.id,
          invoiceData,
        );
      } else {
        result = await ApiServicePurchaseInvoice.createInvoice(invoiceData);
      }

      print('Invoice saved successfully: ${result.invoiceNumber}');

      if (mounted) {
        Navigator.pop(context);
        widget.onInvoiceSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoice != null
                  ? 'Invoice ${result.invoiceNumber} updated successfully'
                  : 'Invoice ${result.invoiceNumber} created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.invoice != null;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Invoice' : 'Create Purchase Invoice',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Invoice Number
                const Text(
                  'Invoice Number*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceNoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Invoice Number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter invoice number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier Invoice Number
                const Text(
                  'Supplier Invoice Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierInvoiceNoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    hintText: 'Enter Supplier Invoice Number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Project/Site
                const Text(
                  'Project / Site*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedSiteId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  items: widget.sites.map((site) {
                    return DropdownMenuItem<int>(
                      value: site.id,
                      child: Text(site.name),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSiteId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a site';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Invoice Materials Section
                const Text(
                  'Invoice Material',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                if (_isLoadingMaterials) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else ...[
                  // Materials Header
                  const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'MATERIAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'QTY | UNIT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'PRICE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'SUBTOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Material Items List
                  if (_materialItems.isNotEmpty) ...[
                    ..._materialItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return MaterialItemRow(
                        item: item,
                        index: index,
                        materials: _materials,
                        units: _units,
                        onUpdate: (updatedItem) =>
                            _updateMaterialItem(index, updatedItem),
                        onRemove: _isSubmitting
                            ? null
                            : () => _removeMaterialItem(index),
                      );
                    }),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Add empty material item row if no items
                    MaterialItemRow(
                      item: MaterialItem(),
                      index: 0,
                      materials: _materials,
                      units: _units,
                      onUpdate: (updatedItem) =>
                          _updateMaterialItem(0, updatedItem),
                      onRemove: null,
                    ),
                  ],
                ],

                // Add Item Button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _addMaterialItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoice Date
                const Text(
                  'Invoice Date*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _invoiceDateController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _isSubmitting ? null : () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select invoice date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Supplier
                const Text(
                  'Supplier*',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedSupplierId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: widget.suppliers.map((supplier) {
                    return DropdownMenuItem<int>(
                      value: supplier.id,
                      child: Text(
                        supplier.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a supplier';
                    }
                    return null;
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 16),

                // Invoice File Upload
                const Text(
                  'Invoice File',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickFile,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file),
                          const SizedBox(height: 4),
                          const Text('Choose File'),
                          const SizedBox(height: 2),
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split('/').last
                                : 'No file chosen',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Allowed: pdf, jpg, jpeg, png, doc, docx',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(isEdit ? 'Update' : 'Create'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MaterialItem {
  int materialId;
  String materialName;
  String quantity;
  String unit;
  String price;
  String subtotal;

  MaterialItem({
    this.materialId = 0,
    this.materialName = '',
    this.quantity = '',
    this.unit = '',
    this.price = '',
    this.subtotal = '0.00',
  });
}

class MaterialItemRow extends StatefulWidget {
  final MaterialItem item;
  final int index;
  final List<MaterialModel> materials;
  final List<UnitModel> units;
  final Function(MaterialItem) onUpdate;
  final Function()? onRemove;

  const MaterialItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.materials,
    required this.units,
    required this.onUpdate,
    this.onRemove,
  });

  @override
  State<MaterialItemRow> createState() => _MaterialItemRowState();
}

class _MaterialItemRowState extends State<MaterialItemRow> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _subtotalController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();

  MaterialModel? _selectedMaterial;

  @override
  void initState() {
    super.initState();

    // Initialize with item data
    _quantityController.text = widget.item.quantity;
    _priceController.text = widget.item.price;
    _subtotalController.text = widget.item.subtotal;
    _unitController.text = widget.item.unit;

    // Find the material by ID for edit mode
    if (widget.item.materialId > 0) {
      try {
        _selectedMaterial = widget.materials.firstWhere(
          (material) => material.id == widget.item.materialId,
        );
        // Set the unit from the material if available
        if (_selectedMaterial?.unit != null) {
          _unitController.text = _selectedMaterial!.unit!.symbol;
        }
      } catch (e) {
        _selectedMaterial = null;
      }
    }
  }

  void _calculateSubtotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final subtotal = quantity * price;

    _subtotalController.text = subtotal.toStringAsFixed(2);

    widget.onUpdate(
      MaterialItem(
        materialId: _selectedMaterial?.id ?? widget.item.materialId,
        materialName: _selectedMaterial?.name ?? widget.item.materialName,
        quantity: _quantityController.text,
        unit: _unitController.text,
        price: _priceController.text,
        subtotal: _subtotalController.text,
      ),
    );
  }

  // Get unique materials by ID to avoid duplicates
  List<MaterialModel> get _uniqueMaterials {
    final uniqueMaterials = <MaterialModel>[];
    final seenIds = <int>{};

    for (final material in widget.materials) {
      if (!seenIds.contains(material.id)) {
        seenIds.add(material.id);
        uniqueMaterials.add(material);
      }
    }
    return uniqueMaterials;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Dropdown
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<MaterialModel>(
              value: _selectedMaterial,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Material',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
              isExpanded: true,
              items: _uniqueMaterials.map((material) {
                return DropdownMenuItem<MaterialModel>(
                  value: material,
                  child: Text(
                    material.name,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                );
              }).toList(),
              onChanged: (MaterialModel? value) {
                setState(() {
                  _selectedMaterial = value;
                  if (value != null) {
                    // Set default price and unit from material
                    _priceController.text = value.price.toStringAsFixed(2);
                    if (value.unit != null) {
                      _unitController.text = value.unit!.symbol;
                    } else {
                      _unitController.text = '';
                    }
                    _calculateSubtotal();
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 4),

          // Quantity and Unit (Unit is now read-only)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateSubtotal(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      hintText: 'Unit',
                    ),
                    readOnly: true,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Price
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateSubtotal(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),

          // Subtotal
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _subtotalController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
              ),
              readOnly: true,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),

          // Delete Button
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }
}