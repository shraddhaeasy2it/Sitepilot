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
    return SupplierCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      isActive: json['is_active'] is bool ? (json['is_active'] ? 1 : 0) : (json['is_active'] ?? 0),
      status: json['status'] ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
      status: json['status'] ?? 0,
      data: dataList.map((item) => SupplierCategory.fromJson(item)).toList(),
    );
  }
}