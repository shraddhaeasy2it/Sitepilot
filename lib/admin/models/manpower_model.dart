import 'package:ecoteam_app/admin/services/manpower_services.dart';

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
  });

  factory ManpowerRecord.fromJson(Map<String, dynamic> json) {
    Map<String, int> counts = {};
    List<ManpowerDetail> details = [];

    if (json['details'] != null) {
      details = (json['details'] as List)
          .map((detail) => ManpowerDetail.fromJson(detail))
          .toList();

      for (var detail in details) {
        if (detail.type != null) {
          counts[detail.type!.name] = detail.count;
        }
      }
    }

    // Calculate total count
    int total = counts.values.fold(0, (sum, count) => sum + count);

    return ManpowerRecord(
      id: json['id'],
      workDate: json['work_date'] ?? '',
      siteId: json['site_id'],
      supplierId: json['supplier_id'],
      workspaceId: json['workspace_id'],
      createdBy: json['created_by'],
      totalCount: json['total_count'] ?? total,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      supplier: json['supplier'] != null ? json['supplier']['name'] ?? '' : '',
      site: json['site'] != null ? json['site']['name'] ?? '' : '',
      manpowerCounts: counts,
      details: details,
    );
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
        }
      }
    });

    return {
      if (id != null) 'id': id,
      'work_date': workDate,
      'site_id': siteId ?? 1,
      'supplier_id': supplierId ?? 1,
      'workspace_id': workspaceId ?? 1,
      'created_by': createdBy ?? 1,
      'details': detailsJson,
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
      id: json['id'],
      manPowerMasterId: json['man_power_master_id'],
      manPowerTypeId: json['man_power_type_id'],
      count: json['count'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
      id: json['id'],
      name: json['name'] ?? '',
      status: json['status'],
      siteId: json['site_id'],
      createdBy: json['created_by'],
      workspaceId: json['workspace_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

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
    Map<int, String> parseMap(dynamic data) {
      final Map<int, String> result = {};
      if (data is Map) {
        data.forEach((key, value) {
          if (key != null && value != null) {
            try {
              result[int.parse(key.toString())] = value.toString();
            } catch (e) {
              // Skip invalid entries
            }
          }
        });
      }
      return result;
    }

    return DropdownData(
      manpowerTypes: parseMap(json['manpowerTypes'] ?? json['manpower_types'] ?? json['manpowerType'] ?? {}),
      suppliers: parseMap(json['suppliers'] ?? {}),
      sites: parseMap(json['sites'] ?? {}),
    );
  }
}