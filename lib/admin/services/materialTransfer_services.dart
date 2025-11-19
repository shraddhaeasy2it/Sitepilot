import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/material_transfer_model.dart';

class MaterialTransferService {
  static const String baseUrl = 'http://sitepilot.easy2it.in';

  // Get all material transfers
  static Future<List<MaterialTransfer>> getMaterialTransfers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/material-transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('API Success: ${data['success']}');
        print('API Message: ${data['message']}');
        
        if (data['success'] == true) {
          List<dynamic> transfers = data['data'];
          print('Number of transfers fetched: ${transfers.length}');
          
          List<MaterialTransfer> materialTransfers = transfers.map((json) {
            try {
              return MaterialTransfer.fromJson(json);
            } catch (e) {
              print('Error parsing transfer: $e');
              print('Problematic JSON: $json');
              return MaterialTransfer(); // Return empty transfer on error
            }
          }).toList();
          
          return materialTransfers;
        } else {
          throw Exception('Failed to load material transfers: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load material transfers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMaterialTransfers: $e');
      throw Exception('Error fetching material transfers: $e');
    }
  }

  // Get sites by workspace ID
  static Future<List<Site>> getSitesByWorkspace(int workspaceId) async {
    try {
      print('Fetching sites for workspace: $workspaceId');
      final formData = await getFormData(workspaceId: workspaceId);
      print('Fetched ${formData.sites.length} sites for workspace $workspaceId');
      return formData.sites;
    } catch (e) {
      print('Error in getSitesByWorkspace: $e');
      throw Exception('Error fetching sites: $e');
    }
  }

  // Get materials by site ID
  static Future<List<Material>> getMaterialsBySite(int siteId) async {
    try {
      print('Fetching materials for site: $siteId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/ajax/get-stock-by-site?site_id=$siteId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Materials API Response Status: ${response.statusCode}');
      print('Materials API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> materialsData = data['data'];
          List<Material> materials = materialsData.map((materialJson) {
            return Material(
              id: materialJson['material_id'] as int?,
              name: materialJson['material_name'] as String?,
              price: materialJson['material_price'] as String?,
              unit: Unit(
                name: materialJson['unit_name'] as String?,
              ),
              purchasedQty: materialJson['purchased_qty'] as String?,
              totalQty: materialJson['total_qty'] != null 
                  ? int.tryParse(materialJson['total_qty'].toString())
                  : null,
            );
          }).toList();
          
          print('Fetched ${materials.length} materials for site $siteId');
          return materials;
        } else {
          throw Exception('Failed to load materials: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load materials. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMaterialsBySite: $e');
      throw Exception('Error fetching materials: $e');
    }
  }

  // Get form data for material transfer (materials, sites, etc.)
  static Future<FormDataResponse> getFormData({int? siteId, int? workspaceId}) async {
    try {
      final Map<String, dynamic> requestBody = {};
      if (siteId != null) requestBody['site_id'] = siteId;
      if (workspaceId != null) requestBody['workspace_id'] = workspaceId;

      print('Fetching form data from: $baseUrl/api/material-transfer/create-data');
      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/material-transfer/create-data'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Form Data API Response Status: ${response.statusCode}');
      print('Form Data API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return FormDataResponse.fromJson(data['data']);
        } else {
          throw Exception('Failed to load form data: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load form data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getFormData: $e');
      throw Exception('Error fetching form data: $e');
    }
  }

  // Get all sites (with workspace filtering capability)
  static Future<List<Site>> getSites({int? workspaceId}) async {
    try {
      if (workspaceId != null) {
        return await getSitesByWorkspace(workspaceId);
      } else {
        final formData = await getFormData();
        return formData.sites;
      }
    } catch (e) {
      print('Error getting sites: $e');
      return [];
    }
  }

  // Get all materials (with site filtering capability)
  static Future<List<Material>> getMaterials({int? siteId}) async {
    try {
      if (siteId != null) {
        return await getMaterialsBySite(siteId);
      } else {
        final formData = await getFormData();
        return formData.materials.values.toList();
      }
    } catch (e) {
      print('Error getting materials: $e');
      return [];
    }
  }

  // Create material transfer - POST API
  static Future<MaterialTransfer> createMaterialTransfer(MaterialTransfer transfer) async {
    try {
      // Prepare the request body according to API documentation
      final Map<String, dynamic> requestBody = {
        'record_date': transfer.recordDate,
        'from_site_id': transfer.fromSiteId,
        'to_site_id': transfer.toSiteId,
        'created_by': transfer.createdBy ?? 1,
        'workspace_id': transfer.workspaceId ?? 1,
        'items': transfer.items.map((item) => {
          'material_id': item.materialId,
          'quantity': item.quantity,
          'unit': item.unit,
          'price': item.price,
        }).toList(),
      };

      print('Creating transfer with data: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/material-transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Create Transfer Response Status: ${response.statusCode}');
      print('Create Transfer Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return MaterialTransfer.fromJson(data['data']);
        } else {
          throw Exception('Failed to create transfer: ${data['message']}');
        }
      } else {
        throw Exception('Failed to create transfer. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating material transfer: $e');
      throw Exception('Error creating material transfer: $e');
    }
  }

  // Update material transfer - PUT API
  static Future<MaterialTransfer> updateMaterialTransfer(MaterialTransfer transfer) async {
    try {
      // Prepare the request body according to API documentation
      final Map<String, dynamic> requestBody = {
        'record_date': transfer.recordDate,
        'from_site_id': transfer.fromSiteId,
        'to_site_id': transfer.toSiteId,
        'created_by': transfer.createdBy ?? 1,
        'workspace_id': transfer.workspaceId ?? 1,
        'items': transfer.items.map((item) => {
          'material_id': item.materialId,
          'quantity': item.quantity,
          'unit': item.unit,
          'price': item.price,
        }).toList(),
      };

      print('Updating transfer ${transfer.id} with data: ${json.encode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/api/material-transfer/${transfer.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Update Transfer Response Status: ${response.statusCode}');
      print('Update Transfer Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return MaterialTransfer.fromJson(data['data']);
        } else {
          throw Exception('Failed to update transfer: ${data['message']}');
        }
      } else {
        throw Exception('Failed to update transfer. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating material transfer: $e');
      throw Exception('Error updating material transfer: $e');
    }
  }

  // Delete material transfer
  static Future<bool> deleteMaterialTransfer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/material-transfer/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Delete Transfer Response Status: ${response.statusCode}');
      print('Delete Transfer Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to delete transfer: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting material transfer: $e');
      throw Exception('Error deleting material transfer: $e');
    }
  }
}

class FormDataResponse {
  final Map<String, Material> materials;
  final List<Site> sites;

  FormDataResponse({
    required this.materials,
    required this.sites,
  });

  factory FormDataResponse.fromJson(Map<String, dynamic> json) {
    // Parse materials - they come as a map with material IDs as keys
    final Map<String, Material> materialsMap = {};
    if (json['materials'] is Map) {
      json['materials'].forEach((key, materialData) {
        try {
          final material = Material.fromJson(materialData);
          materialsMap[key] = material;
        } catch (e) {
          print('Error parsing material $key: $e');
        }
      });
    }

    // Parse sites - they come as a list
    final List<Site> sitesList = [];
    if (json['sites'] is List) {
      for (var siteData in json['sites']) {
        try {
          sitesList.add(Site.fromJson(siteData));
        } catch (e) {
          print('Error parsing site: $e');
        }
      }
    }

    return FormDataResponse(
      materials: materialsMap,
      sites: sitesList,
    );
  }
}