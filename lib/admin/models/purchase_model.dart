
import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';

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
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceDate: json['invoice_date']?.toString() ?? '',
      supplierInvoiceNumber: json['supplier_invoice_number']?.toString() ?? '',
      supplierId: int.tryParse(json['supplier_id']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? '',
      invoiceFile: json['invoice_file']?.toString(),
      siteId: int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      invoiceType: json['invoice_type']?.toString() ?? 'general_po', // Default value
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => InvoiceItem.fromJson(item))
                .toList()
          : null,
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
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
  final MaterialModel? material;

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
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      purchaseInvoiceId: int.tryParse(json['purchase_invoice_id']?.toString() ?? '0') ?? 0,
      materialId: int.tryParse(json['material_id']?.toString() ?? '0') ?? 0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unit: json['unit']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
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
  final int? gstId; // Added gstId
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
    this.gstId, // Added gstId
    this.unit,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      unitId: int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      reorderLevel: int.tryParse(json['reorder_level']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      image: json['image']?.toString(),
      siteId: json['site_id'] != null ? int.tryParse(json['site_id'].toString()) : null,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      gstId: json['gst_id'] != null ? int.tryParse(json['gst_id'].toString()) : null,
      unit: json['unit'] != null
          ? (json['unit'] is Map
              ? UnitModel.fromJson(Map<String, dynamic>.from(json['unit']))
              : UnitModel(
                  id: 0,
                  name: json['unit'].toString(),
                  symbol: json['unit'].toString(),
                  isActive: 1,
                  createdBy: 0,
                  workspaceId: 0,
                  status: 'active',
                  createdAt: '',
                  updatedAt: '',
                ))
          : null,
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
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: int.tryParse(json['is_active']?.toString() ?? '0') ?? 0,
      siteId: json['site_id'] != null ? int.tryParse(json['site_id'].toString()) : null,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
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
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      range: json['range']?.toString(),
      description: json['description']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      budget: double.tryParse(json['budget']?.toString() ?? '0') ?? 0.0,
      isActive: int.tryParse(json['is_active']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      profileProgress: json['profile_progress']?.toString() ?? '',
      progress: json['progress']?.toString() ?? '',
      taskProgress: json['task_progress']?.toString() ?? '',
      test: json['test']?.toString(),
      estimateSize:
          double.tryParse(json['estimate_size']?.toString() ?? '0') ?? 0.0,
      copylinksetting: json['copylinksetting']?.toString() ?? '',
      password: json['password']?.toString(),
      workspaceId: int.tryParse(json['workspace_id']?.toString() ?? '0') ?? 0,
      createdBy: int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}