class MaterialModel {
  final int id;
  final String name;
  final String sku;
  final int categoryId;
  final int unitId;
  final String description;
  final String price;
  final int reorderLevel;
  final String status;
  final String? image;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String createdAt;
  final String updatedAt;
  final Unit? unit;
  final Category? category;

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
    this.category,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['category_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0.00',
      reorderLevel: json['reorder_level'] ?? 0,
      status: json['status'] ?? '',
      image: json['image'],
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}

class Unit {
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

  Unit({
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

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
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
}

class Category {
  final int id;
  final String name;
  final int isActive;
  final int? siteId;
  final int createdBy;
  final int workspaceId;
  final String status;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.isActive,
    this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? 0,
      siteId: json['site_id'],
      createdBy: json['created_by'] ?? 0,
      workspaceId: json['workspace_id'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
class ToolModel {
  final int id;
  final int materialId;
  final int quantity;
  final String operationalStatus;
  final int siteId;
  final int createdBy;
  final int workspaceId;
  final String status;
  final String createdAt;
  final String updatedAt;
  final MaterialModel? material;

  ToolModel({
    required this.id,
    required this.materialId,
    required this.quantity,
    required this.operationalStatus,
    required this.siteId,
    required this.createdBy,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.material,
  });

  factory ToolModel.fromJson(Map<String, dynamic> json) {
    return ToolModel(
      id: json['id'] ?? 0,
      materialId: _parseInt(json['material_id']),
      quantity: _parseInt(json['quantity']),
      operationalStatus: json['operational_status'] ?? '',
      siteId: _parseInt(json['site_id']),
      createdBy: _parseInt(json['created_by']),
      workspaceId: _parseInt(json['workspace_id']),
      status: json['status']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
      'operational_status': operationalStatus,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
    };
  }
}

class ToolResponse {
  final String message;
  final List<ToolModel> data;

  ToolResponse({
    required this.message,
    required this.data,
  });

  factory ToolResponse.fromJson(Map<String, dynamic> json) {
    return ToolResponse(
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ToolModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class SingleToolResponse {
  final String message;
  final ToolModel data;

  SingleToolResponse({
    required this.message,
    required this.data,
  });

  factory SingleToolResponse.fromJson(Map<String, dynamic> json) {
    return SingleToolResponse(
      message: json['message'] ?? '',
      data: ToolModel.fromJson(json['data'] ?? {}),
    );
  }
}