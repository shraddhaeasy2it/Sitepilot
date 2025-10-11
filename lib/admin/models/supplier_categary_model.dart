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
      isActive: json['is_active'] ?? 0,
      status: json['status'] ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'site_id': siteId?.toString(),
      'created_by': createdBy.toString(),
      'workspace_id': workspaceId.toString(),
      'is_active': isActive.toString(),
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };

    // Only include id if it's not 0 (for updates)
    if (id != 0) {
      data['id'] = id.toString();
    }

    return data;
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
    return SupplierCategoryResponse(
      status: json['Status'] ?? 0,
      data: (json['data'] as List? ?? [])
          .map((item) => SupplierCategory.fromJson(item))
          .toList(),
    );
  }
}