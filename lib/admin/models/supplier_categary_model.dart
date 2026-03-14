// models/supplier_category_model.dart
class SupplierCategory {
  int id;
  String name;
  String? description;
  int? siteId;
  int createdBy;
  int workspaceId;
  int isActive;
  String status;
  String createdAt;
  String updatedAt;

  SupplierCategory({
    required this.id,
    required this.name,
    this.description,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.isActive,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierCategory.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is bool) return value ? 1 : 0;
      return 0;
    }

    int? _parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return SupplierCategory(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      siteId: _parseNullableInt(json['site_id']),
      createdBy: _parseInt(json['created_by']),
      workspaceId: _parseInt(json['workspace_id']),
      isActive: _parseInt(json['is_active']),
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'is_active': isActive,
      'status': status,
    };
  }

  SupplierCategory copyWith({
    int? id,
    String? name,
    String? description,
    int? siteId,
    int? createdBy,
    int? workspaceId,
    int? isActive,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return SupplierCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      workspaceId: workspaceId ?? this.workspaceId,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SupplierCategoryResponse {
  int status;
  List<SupplierCategory> data;

  SupplierCategoryResponse({
    required this.status,
    required this.data,
  });

  factory SupplierCategoryResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataList = [];
    
    if (json['data'] != null) {
      if (json['data'] is List) {
        dataList = json['data'];
      } else if (json['data'] is Map && json['data']['data'] != null) {
        dataList = json['data']['data'];
      }
    }

    return SupplierCategoryResponse(
      status: json['status'] is int ? json['status'] : (int.tryParse(json['status']?.toString() ?? '0') ?? 0),
      data: dataList.map((item) => SupplierCategory.fromJson(item)).toList(),
    );
  }
}