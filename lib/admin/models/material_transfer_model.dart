
class MaterialTransfer {
  int? id;
  String? recordNumber;
  String? recordDate;
  int? fromSiteId;
  int? toSiteId;
  String? totalAmount;
  String? status;
  int? createdBy;
  int? workspaceId;
  String? recordFile;
  String? createdAt;
  String? updatedAt;
  List<TransferItem> items;
  Site? fromSite;
  Site? toSite;

  MaterialTransfer({
    this.id,
    this.recordNumber,
    this.recordDate,
    this.fromSiteId,
    this.toSiteId,
    this.totalAmount,
    this.status,
    this.createdBy,
    this.workspaceId,
    this.recordFile,
    this.createdAt,
    this.updatedAt,
    List<TransferItem>? items,
    this.fromSite,
    this.toSite,
  }) : items = items ?? [];

  factory MaterialTransfer.fromJson(Map<String, dynamic> json) {
    return MaterialTransfer(
      id: json['id'] as int?,
      recordNumber: json['record_number'] as String?,
      recordDate: json['record_date'] as String?,
      fromSiteId: json['from_site_id'] as int?,
      toSiteId: json['to_site_id'] as int?,
      totalAmount: json['total_amount']?.toString(),
      status: json['status'] as String?,
      createdBy: json['created_by'] as int?,
      workspaceId: json['workspace_id'] as int?,
      recordFile: json['record_file'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => TransferItem.fromJson(i)).toList()
          : [],
      fromSite: json['from_site'] != null ? Site.fromJson(json['from_site']) : null,
      toSite: json['to_site'] != null ? Site.fromJson(json['to_site']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_number': recordNumber,
      'record_date': recordDate,
      'from_site_id': fromSiteId,
      'to_site_id': toSiteId,
      'total_amount': totalAmount,
      'status': status,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'record_file': recordFile,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'record_date': recordDate,
      'from_site_id': fromSiteId,
      'to_site_id': toSiteId,
      'created_by': createdBy ?? 1,
      'workspace_id': workspaceId ?? 1,
      'items': items.map((item) => item.toApiJson()).toList(),
    };
  }

  String get fromSiteName => fromSite?.name ?? 'Site ${fromSiteId ?? 'N/A'}';
  String get toSiteName => toSite?.name ?? 'Site ${toSiteId ?? 'N/A'}';
}

class TransferItem {
  int? id;
  int? materialTransferId;
  int? materialId;
  String? quantity;
  String? unit;
  String? price;
  String? subtotal;
  String? receivedAt;
  String? createdAt;
  String? updatedAt;
  Material? material;

  TransferItem({
    this.id,
    this.materialTransferId,
    this.materialId,
    this.quantity,
    this.unit,
    this.price,
    this.subtotal,
    this.receivedAt,
    this.createdAt,
    this.updatedAt,
    this.material,
  });

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    // Handle material data - it might be a list or single object
    Material? materialData;
    if (json['material'] != null) {
      if (json['material'] is List) {
        if ((json['material'] as List).isNotEmpty) {
          materialData = Material.fromJson((json['material'] as List).first);
        }
      } else {
        materialData = Material.fromJson(json['material']);
      }
    }

    return TransferItem(
      id: json['id'] as int?,
      materialTransferId: json['material_transfer_id'] as int?,
      materialId: json['material_id'] as int?,
      quantity: json['quantity']?.toString(),
      unit: json['unit'] as String?,
      price: json['price']?.toString(),
      subtotal: json['subtotal']?.toString(),
      receivedAt: json['received_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      material: materialData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_transfer_id': materialTransferId,
      'material_id': materialId,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'subtotal': subtotal,
      'received_at': receivedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'material': material?.toJson(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
      'unit': unit,
      'price': price,
    };
  }
}

class Material {
  int? id;
  String? name;
  String? sku;
  int? categoryId;
  int? unitId;
  String? description;
  String? price;
  int? reorderLevel;
  String? status;
  String? image;
  int? siteId;
  int? createdBy;
  int? workspaceId;
  String? createdAt;
  String? updatedAt;
  Unit? unit;
  String? purchasedQty;
  int? totalQty;

  Material({
    this.id,
    this.name,
    this.sku,
    this.categoryId,
    this.unitId,
    this.description,
    this.price,
    this.reorderLevel,
    this.status,
    this.image,
    this.siteId,
    this.createdBy,
    this.workspaceId,
    this.createdAt,
    this.updatedAt,
    this.unit,
    this.purchasedQty,
    this.totalQty,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      unitId: json['unit_id'] != null ? int.tryParse(json['unit_id'].toString()) : null,
      description: json['description'] as String?,
      price: json['price']?.toString(),
      reorderLevel: json['reorder_level'] != null ? int.tryParse(json['reorder_level'].toString()) : null,
      status: json['status'] as String?,
      image: json['image'] as String?,
      siteId: json['site_id'] != null ? int.tryParse(json['site_id'].toString()) : null,
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      workspaceId: json['workspace_id'] != null ? int.tryParse(json['workspace_id'].toString()) : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      purchasedQty: json['purchased_qty'] as String?,
      totalQty: json['total_qty'] != null ? int.tryParse(json['total_qty'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category_id': categoryId,
      'unit_id': unitId,
      'description': description,
      'price': price,
      'reorder_level': reorderLevel,
      'status': status,
      'image': image,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'unit': unit?.toJson(),
      'purchased_qty': purchasedQty,
      'total_qty': totalQty,
    };
  }

  String get displayName => '$name (₹$price)';
  String get displayNameWithStock => '$name (₹$price) - Stock: ${totalQty ?? 0}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Material && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Unit {
  int? id;
  String? name;
  String? symbol;
  String? description;
  int? isActive;
  int? siteId;
  int? createdBy;
  int? workspaceId;
  String? status;
  String? createdAt;
  String? updatedAt;

  Unit({
    this.id,
    this.name,
    this.symbol,
    this.description,
    this.isActive,
    this.siteId,
    this.createdBy,
    this.workspaceId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] != null ? int.tryParse(json['is_active'].toString()) : null,
      siteId: json['site_id'] != null ? int.tryParse(json['site_id'].toString()) : null,
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      workspaceId: json['workspace_id'] != null ? int.tryParse(json['workspace_id'].toString()) : null,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'description': description,
      'is_active': isActive,
      'site_id': siteId,
      'created_by': createdBy,
      'workspace_id': workspaceId,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Site {
  int? id;
  String? name;
  String? status;
  String? image;
  String? description;
  String? startDate;
  String? endDate;
  int? budget;
  int? isActive;
  String? type;
  String? currency;
  String? projectProgress;
  String? progress;
  String? taskProgress;
  dynamic tags;
  int? estimatedHrs;
  String? copyLinkSetting;
  String? password;
  int? workspace;
  int? createdBy;
  String? createdAt;
  String? updatedAt;

  Site({
    this.id,
    this.name,
    this.status,
    this.image,
    this.description,
    this.startDate,
    this.endDate,
    this.budget,
    this.isActive,
    this.type,
    this.currency,
    this.projectProgress,
    this.progress,
    this.taskProgress,
    this.tags,
    this.estimatedHrs,
    this.copyLinkSetting,
    this.password,
    this.workspace,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] as String?,
      status: json['status'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      budget: json['budget'] != null ? int.tryParse(json['budget'].toString()) : null,
      isActive: json['is_active'] != null ? int.tryParse(json['is_active'].toString()) : null,
      type: json['type'] as String?,
      currency: json['currency'] as String?,
      projectProgress: json['project_progress'] as String?,
      progress: json['progress'] as String?,
      taskProgress: json['task_progress'] as String?,
      tags: json['tags'],
      estimatedHrs: json['estimated_hrs'] != null ? int.tryParse(json['estimated_hrs'].toString()) : null,
      copyLinkSetting: json['copylinksetting'] as String?,
      password: json['password'] as String?,
      workspace: json['workspace'] != null ? int.tryParse(json['workspace'].toString()) : null,
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'image': image,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'budget': budget,
      'is_active': isActive,
      'type': type,
      'currency': currency,
      'project_progress': projectProgress,
      'progress': progress,
      'task_progress': taskProgress,
      'tags': tags,
      'estimated_hrs': estimatedHrs,
      'copylinksetting': copyLinkSetting,
      'password': password,
      'workspace': workspace,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}