class MachineryCategory {
  int id;
  String name;
  String description;
  int? siteId;
  int createdBy;
  int workspaceId;
  int isActive;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;

  MachineryCategory({
    required this.id,
    required this.name,
    required this.description,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.isActive,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory MachineryCategory.fromJson(Map<String, dynamic> json) {
    return MachineryCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? json['boxspace_id'] ?? 0,
      isActive: json['is_active'] ?? 1,
      status: json['status'] ?? json['state1'] ?? '0',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'is_active': isActive,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  MachineryCategory copyWith({
    String? name,
    String? description,
    int? siteId,
    int? createdBy,
    int? workspaceId,
    int? isActive,
    String? status,
  }) {
    return MachineryCategory(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      siteId: siteId ?? this.siteId,
      createdBy: createdBy ?? this.createdBy,
      workspaceId: workspaceId ?? this.workspaceId,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ApiResponse {
  int status;
  dynamic data;
  String message;

  ApiResponse({
    required this.status,
    required this.data,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? 0,
      data: json['data'],
      message: json['message'] ?? '',
    );
  }
}