
class PurchaseOrderModel {
  final int id;
  final String? poNumber;
  final String? poDate;
  final String? supplierInvoiceNumber;
  final String? supplierId;
  final String? grandTotal;
  final String? deliveryDate;
  final String? referenceFile;
  final String? deliveryTermsConditions;
  final String? paymentTermsConditions;
  final String? remark;
  final String? status;
  final String? taxType;
  final String? totalTaxableValue;
  final String? totalCgst;
  final String? totalSgst;
  final String? totalIgst;
  final String? totalTax;
  final String? totalDiscount;
  final String? additionalCharge;
  final String? additionalDeduction;
  final String? additionalDiscount;
  final String? siteId;
  final String? createdBy;
  final String? workspaceId;
  final String? indentId;
  final String? description;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;
  final String? poPdf;
  final POSupplier? supplier;
  final POCreator? creator;
  final POIndent? indent;
  final List<POItem>? items;
  final POSite? site;

  PurchaseOrderModel({
    required this.id,
    this.poNumber,
    this.poDate,
    this.supplierInvoiceNumber,
    this.supplierId,
    this.grandTotal,
    this.deliveryDate,
    this.referenceFile,
    this.deliveryTermsConditions,
    this.paymentTermsConditions,
    this.remark,
    this.status,
    this.taxType,
    this.totalTaxableValue,
    this.totalCgst,
    this.totalSgst,
    this.totalIgst,
    this.totalTax,
    this.totalDiscount,
    this.additionalCharge,
    this.additionalDeduction,
    this.additionalDiscount,
    this.siteId,
    this.createdBy,
    this.workspaceId,
    this.indentId,
    this.description,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.poPdf,
    this.supplier,
    this.creator,
    this.indent,
    this.items,
    this.site,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      poNumber: json['po_number']?.toString(),
      poDate: json['po_date']?.toString(),
      supplierInvoiceNumber: json['supplier_invoice_number']?.toString(),
      supplierId: json['supplier_id']?.toString(),
      grandTotal: json['grand_total']?.toString(),
      deliveryDate: json['delivery_date']?.toString(),
      referenceFile: json['reference_file']?.toString(),
      deliveryTermsConditions: json['delivery_terms_conditions']?.toString(),
      paymentTermsConditions: json['payment_terms_conditions']?.toString(),
      remark: json['remark']?.toString(),
      status: json['status']?.toString(),
      taxType: json['tax_type']?.toString(),
      totalTaxableValue: json['total_taxable_value']?.toString(),
      totalCgst: json['total_cgst']?.toString(),
      totalSgst: json['total_sgst']?.toString(),
      totalIgst: json['total_igst']?.toString(),
      totalTax: json['total_tax']?.toString(),
      totalDiscount: json['total_discount']?.toString(),
      additionalCharge: json['additional_charge']?.toString(),
      additionalDeduction: json['additional_deduction']?.toString(),
      additionalDiscount: json['additional_discount']?.toString(),
      siteId: json['site_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      workspaceId: json['workspace_id']?.toString(),
      indentId: json['indent_id']?.toString(),
      description: json['description']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      poPdf: json['po_pdf']?.toString(),
      supplier: json['supplier'] != null ? POSupplier.fromJson(json['supplier']) : null,
      creator: json['creator'] != null ? POCreator.fromJson(json['creator']) : null,
      indent: json['indent'] != null ? POIndent.fromJson(json['indent']) : null,
      items: (json['items'] as List?)?.map((i) => POItem.fromJson(i)).toList(),
      site: json['site'] != null ? POSite.fromJson(json['site']) : null,
    );
  }
}

class POSupplier {
  final int id;
  final String? name;

  POSupplier({required this.id, this.name});

  factory POSupplier.fromJson(Map<String, dynamic> json) {
    return POSupplier(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name']?.toString(),
    );
  }
}

class POCreator {
  final int id;
  final String? name;

  POCreator({required this.id, this.name});

  factory POCreator.fromJson(Map<String, dynamic> json) {
    return POCreator(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name']?.toString(),
    );
  }
}

class POIndent {
  final int id;
  final String? indentNumber;

  POIndent({required this.id, this.indentNumber});

  factory POIndent.fromJson(Map<String, dynamic> json) {
    return POIndent(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      indentNumber: json['indent_number']?.toString(),
    );
  }
}

class POItem {
  final int id;
  final String? quantity;
  final String? unit;
  final String? price;
  final String? subtotal;
  final String? remarks;
  final String? taxId; // Added taxId
  final String? discount; // Added discount
  final POMaterial? material;

  POItem({
    required this.id,
    this.quantity,
    this.unit,
    this.price,
    this.subtotal,
    this.remarks,
    this.taxId, // Added taxId
    this.discount, // Added discount
    this.material,
  });

  factory POItem.fromJson(Map<String, dynamic> json) {
    return POItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      price: json['price']?.toString(),
      subtotal: json['subtotal']?.toString(),
      remarks: json['remarks']?.toString(),
      taxId: json['tax_id']?.toString(),
      discount: json['discount']?.toString(),
      material: json['material'] != null ? POMaterial.fromJson(json['material']) : null,
    );
  }
}

class POMaterial {
  final int id;
  final String? name;

  POMaterial({required this.id, this.name});

  factory POMaterial.fromJson(Map<String, dynamic> json) {
    return POMaterial(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name']?.toString(),
    );
  }
}

class POSite {
  final int id;
  final String? name;

  POSite({required this.id, this.name});

  factory POSite.fromJson(Map<String, dynamic> json) {
    return POSite(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name']?.toString(),
    );
  }
}
