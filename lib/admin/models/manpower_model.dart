import 'package:ecoteam_app/admin/services/manpower_services.dart';

class DropdownData {
  final Map<int, String> manpowerTypes;
  final Map<int, String> suppliers;
  final Map<int, String> sites;

  DropdownData({
    required this.manpowerTypes,
    required this.suppliers,
    required this.sites,
  });

  factory DropdownData.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing dropdown JSON...');
      
      Map<int, String> parseMap(Map<dynamic, dynamic>? data) {
        final Map<int, String> result = {};
        
        if (data == null) {
          print('Data is null');
          return result;
        }
        
        data.forEach((key, value) {
          if (key != null && value != null) {
            try {
              final id = int.tryParse(key.toString());
              if (id != null && value.toString().isNotEmpty) {
                result[id] = value.toString();
              }
            } catch (e) {
              print('Skipping invalid entry: $key -> $value');
            }
          }
        });
        
        return result;
      }

      // Directly parse the maps from the JSON
      final manpowerTypes = parseMap(json['manpowerTypes']);
      final suppliers = parseMap(json['suppliers']);
      final sites = parseMap(json['sites']);
      
      print('Parsed: ${manpowerTypes.length} types, ${suppliers.length} suppliers, ${sites.length} sites');
      
      return DropdownData(
        manpowerTypes: manpowerTypes,
        suppliers: suppliers,
        sites: sites,
      );
      
    } catch (e) {
      print('Error parsing DropdownData: $e');
      print('Full JSON data: $json');
      
      // Return empty data instead of throwing to allow app to continue
      return DropdownData(
        manpowerTypes: {},
        suppliers: {},
        sites: {},
      );
    }
  }
}

// Rest of your model classes remain the same...
class ManpowerRecord {
  int? id;
  String workDate;
  String supplier;
  String site;
  Map<String, int> manpowerCounts;
  int? totalCount;
  int? siteId;
  int? supplierId;
  int? workspaceId;
  int? createdBy;
  String? createdAt;
  String? updatedAt;
  List<ManpowerDetail>? details;
  int? activityId;
  int? activityCompletedId;

  ManpowerRecord({
    this.id,
    required this.workDate,
    required this.supplier,
    required this.site,
    required this.manpowerCounts,
    this.totalCount,
    this.siteId,
    this.supplierId,
    this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.details,
    this.activityId,
    this.activityCompletedId,
  });

  factory ManpowerRecord.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, int> counts = {};
      List<ManpowerDetail> details = [];

      if (json['details'] != null && json['details'] is List) {
        details = (json['details'] as List)
            .map((detail) => ManpowerDetail.fromJson(detail))
            .toList();

        for (var detail in details) {
          if (detail.type != null && detail.type!.name.isNotEmpty) {
            counts[detail.type!.name] = detail.count;
          }
        }
      }

      // Calculate total count: Prioritize 'total_count' from API, fallback to details sum
      int total = 0;
      if (json['total_count'] != null) {
        if (json['total_count'] is int) {
          total = json['total_count'];
        } else if (json['total_count'] is String) {
          total = int.tryParse(json['total_count']) ?? 0;
        }
      } else {
        total = details.fold(0, (sum, detail) => sum + detail.count);
      }

      // Get supplier and site names from the maps if not provided in JSON
      String supplierName = '';
      if (json['supplier'] != null && json['supplier'] is Map) {
        supplierName = json['supplier']['name']?.toString() ?? '';
      } else if (json['supplier_id'] != null) {
        supplierName = ManpowerService.getSupplierNameById(int.tryParse(json['supplier_id'].toString()) ?? 0);
      }

      String siteName = '';
      if (json['site'] != null && json['site'] is Map) {
        siteName = json['site']['name']?.toString() ?? '';
      } else if (json['site_id'] != null) {
        siteName = ManpowerService.getSiteNameById(int.tryParse(json['site_id'].toString()) ?? 0);
      }

      return ManpowerRecord(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
        workDate: json['work_date']?.toString() ?? '',
        siteId: json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id']?.toString() ?? '0'),
        supplierId: json['supplier_id'] is int ? json['supplier_id'] : int.tryParse(json['supplier_id']?.toString() ?? '0'),
        workspaceId: json['workspace_id'] is int ? json['workspace_id'] : int.tryParse(json['workspace_id']?.toString() ?? '0'),
        createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? '0'),
        totalCount: total,
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        supplier: supplierName,
        site: siteName,
        manpowerCounts: counts,
        details: details,
        activityId: json['activity_id'] is int ? json['activity_id'] : int.tryParse(json['activity_id']?.toString() ?? ''),
        activityCompletedId: json['activity_completed_id'] is int ? json['activity_completed_id'] : int.tryParse(json['activity_completed_id']?.toString() ?? ''),
      );
    } catch (e) {
      print('Error parsing ManpowerRecord: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> detailsJson = [];
    
    manpowerCounts.forEach((type, count) {
      if (count > 0) {
        final typeId = _getTypeIdFromName(type);
        if (typeId != 0) {
          detailsJson.add({
            'man_power_type_id': typeId,
            'count': count,
          });
        } else {
          // Debug print if type ID not found
          print('Warning: Manpower type "$type" not found in map (ID=0), skipping.');
        }
      }
    });

    if (detailsJson.isEmpty && manpowerCounts.isNotEmpty) {
       print('Warning: detailsJson is empty but manpowerCounts is not! This means no types were mapped.');
       print('Available types in map: ${ManpowerService.typeMap.keys.length}');
    }

    return {
      if (id != null) 'id': id,
      'work_date': workDate,
      'site_id': siteId ?? 1,
      'supplier_id': supplierId ?? 1,
      'workspace_id': workspaceId ?? 1,
      'created_by': createdBy ?? 1,
      'details': detailsJson,
      if (activityId != null) 'activity_id': activityId,
      if (activityCompletedId != null) 'activity_completed_id': activityCompletedId,
    };
  }

  int _getTypeIdFromName(String name) {
    return ManpowerService.typeMap.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == name.toLowerCase(),
          orElse: () => MapEntry(0, ''),
        )
        .key;
  }
}

class ManpowerDetail {
  int? id;
  int? manPowerMasterId;
  int? manPowerTypeId;
  int count;
  String? createdAt;
  String? updatedAt;
  ManpowerType? type;

  ManpowerDetail({
    this.id,
    this.manPowerMasterId,
    this.manPowerTypeId,
    required this.count,
    this.createdAt,
    this.updatedAt,
    this.type,
  });

  factory ManpowerDetail.fromJson(Map<String, dynamic> json) {
    return ManpowerDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      manPowerMasterId: json['man_power_master_id'] is int ? json['man_power_master_id'] : int.tryParse(json['man_power_master_id']?.toString() ?? '0'),
      manPowerTypeId: json['man_power_type_id'] is int ? json['man_power_type_id'] : int.tryParse(json['man_power_type_id']?.toString() ?? '0'),
      count: json['count'] is int ? json['count'] : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      type: json['type'] != null ? ManpowerType.fromJson(json['type']) : null,
    );
  }
}

class ManpowerType {
  int? id;
  String name;
  int? status;
  int? siteId;
  int? createdBy;
  int? workspaceId;
  String? createdAt;
  String? updatedAt;

  ManpowerType({
    this.id,
    required this.name,
    this.status,
    this.siteId,
    this.createdBy,
    this.workspaceId,
    this.createdAt,
    this.updatedAt,
  });

  factory ManpowerType.fromJson(Map<String, dynamic> json) {
    return ManpowerType(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      name: json['name']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '0'),
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse(json['site_id']?.toString() ?? '0'),
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? '0'),
      workspaceId: json['workspace_id'] is int ? json['workspace_id'] : int.tryParse(json['workspace_id']?.toString() ?? '0'),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}