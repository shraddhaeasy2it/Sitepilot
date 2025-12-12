
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
  final String invoiceType; // Added invoice type field

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
    required this.invoiceType, // Added invoice type field
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
      invoiceType: json['invoice_type'] ?? 'general_po', // Default value
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
      'invoice_type': invoiceType, // Added invoice type field
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