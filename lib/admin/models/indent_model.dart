class IndentModel {
  final int id;
  final String? indentNumber;
  final String? indentDate;
  final String? supplierInvoiceNumber;
  final String? supplierId;
  final String? totalAmount;
  final String? status;
  final String? siteId;
  final String? createdBy;
  final String? workspaceId;
  final String? description;
  final String? rejectionReason;
  final String? deliveryDate;
  final String? referenceFile;
  final String? createdAt;
  final String? updatedAt;
  final IndentSupplier? supplier;
  final IndentCreator? creator;
  final List<IndentItem>? items;
  final List<IndentCreator>? assignedUsers;

  IndentModel({
    required this.id,
    this.indentNumber,
    this.indentDate,
    this.supplierInvoiceNumber,
    this.supplierId,
    this.totalAmount,
    this.status,
    this.siteId,
    this.createdBy,
    this.workspaceId,
    this.description,
    this.rejectionReason,
    this.deliveryDate,
    this.referenceFile,
    this.createdAt,
    this.updatedAt,
    this.supplier,
    this.creator,
    this.items,
    this.assignedUsers,
  });

  factory IndentModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    List<IndentItem>? parsedItems = itemsList?.map((i) => IndentItem.fromJson(i)).toList();

    return IndentModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      indentNumber: json['indent_number']?.toString(),
      indentDate: json['indent_date']?.toString(),
      supplierInvoiceNumber: json['supplier_invoice_number']?.toString(),
      supplierId: json['supplier_id']?.toString(),
      totalAmount: json['total_amount']?.toString(),
      status: json['status']?.toString(),
      siteId: json['site_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      workspaceId: json['workspace_id']?.toString(),
      description: json['description']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      referenceFile: json['reference_file']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      supplier: _parseSupplier(json['supplier']),
      creator: _parseCreator(json['creator'] ?? json['user']),
      items: parsedItems,
      assignedUsers: (json['assigned_users'] as List?)?.map((i) => IndentCreator.fromJson(i)).toList(),
    );
  }

  static IndentSupplier? _parseSupplier(dynamic data) {
    if (data == null || data is! Map) return null;
    try {
      return IndentSupplier.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  static IndentCreator? _parseCreator(dynamic data) {
    if (data == null || data is! Map) return null;
    try {
      return IndentCreator.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }
}

class IndentSupplier {
  final int id;
  final String? name;

  IndentSupplier({required this.id, this.name});

  factory IndentSupplier.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) parsedId = json['id'];
      else if (json['id'] is String) parsedId = int.tryParse(json['id']) ?? 0;
    }
    
    return IndentSupplier(
      id: parsedId,
      name: json['name']?.toString() ?? json['first_name']?.toString() ?? json['supplier_name']?.toString(),
    );
  }
}

class IndentCreator {
  final int id;
  final String? name;

  IndentCreator({required this.id, this.name});

  factory IndentCreator.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] != null) {
      if (json['id'] is int) parsedId = json['id'];
      else if (json['id'] is String) parsedId = int.tryParse(json['id']) ?? 0;
    }
    
    return IndentCreator(
      id: parsedId,
      name: json['name']?.toString() ?? json['first_name']?.toString() ?? json['user_name']?.toString(),
    );
  }
}

class IndentItem {
  final int id;
  final String? indentId;
  final String? materialId;
  final String? quantity;
  final String? unit;
  final String? price;
  final String? subtotal;
  final String? remarks;
  final String? remainingQuantity;
  final IndentMaterial? material;

  IndentItem({
    required this.id,
    this.indentId,
    this.materialId,
    this.quantity,
    this.unit,
    this.price,
    this.subtotal,
    this.remarks,
    this.remainingQuantity,
    this.material,
  });

  factory IndentItem.fromJson(Map<String, dynamic> json) {
    return IndentItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      indentId: json['indent_id']?.toString(),
      materialId: json['material_id']?.toString(),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      price: json['price']?.toString(),
      subtotal: json['subtotal']?.toString(),
      remarks: json['remarks']?.toString(),
      remainingQuantity: json['remaining_quantity']?.toString(),
      material: json['material'] != null ? IndentMaterial.fromJson(json['material']) : null,
    );
  }
}

class IndentMaterial {
  final int id;
  final String? name;
  final String? sku;

  IndentMaterial({required this.id, this.name, this.sku});

  factory IndentMaterial.fromJson(Map<String, dynamic> json) {
    return IndentMaterial(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
    );
  }
}
