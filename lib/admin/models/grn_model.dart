import 'package:ecoteam_app/admin/models/Allsupplier_model.dart';
import 'package:ecoteam_app/admin/models/purchase_order_model.dart';

class GRNModel {
  final int id;
  final String? grnNumber;
  final String? poId;
  final String? supplierId;
  final String? siteId;
  final String? grnDate;
  final String? deliveryChallanNumber;
  final String? vehicleNumber;
  final String? gateEntryNumber;
  final String? deliveryChallanFile;
  final String? referenceFile;
  final String? description;
  final String? receivedBy;
  final String? remarks;
  final String? status;
  final String? createdBy;
  final String? workspaceId;
  final String? createdAt;
  final String? updatedAt;
  final PurchaseOrderModel? purchaseOrder;
  final Supplier? supplier;
  final GRNSite? site;
  final GRNCreator? creator;
  final List<GRNItem>? items;

  GRNModel({
    required this.id,
    this.grnNumber,
    this.poId,
    this.supplierId,
    this.siteId,
    this.grnDate,
    this.deliveryChallanNumber,
    this.vehicleNumber,
    this.gateEntryNumber,
    this.deliveryChallanFile,
    this.referenceFile,
    this.description,
    this.receivedBy,
    this.remarks,
    this.status,
    this.createdBy,
    this.workspaceId,
    this.createdAt,
    this.updatedAt,
    this.purchaseOrder,
    this.supplier,
    this.site,
    this.creator,
    this.items,
  });

  factory GRNModel.fromJson(Map<String, dynamic> json) {
    return GRNModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      grnNumber: json['grn_number']?.toString(),
      poId: json['po_id']?.toString(),
      supplierId: json['supplier_id']?.toString(),
      siteId: json['site_id']?.toString(),
      grnDate: json['grn_date']?.toString(),
      deliveryChallanNumber: json['delivery_challan_number']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      gateEntryNumber: json['gate_entry_number']?.toString(),
      deliveryChallanFile: json['delivery_challan_file']?.toString(),
      referenceFile: json['reference_file']?.toString(),
      description: json['description']?.toString(),
      receivedBy: json['received_by']?.toString(),
      remarks: json['remarks']?.toString(),
      status: json['status']?.toString(),
      createdBy: json['created_by']?.toString(),
      workspaceId: json['workspace_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      purchaseOrder: json['purchase_order'] != null
          ? PurchaseOrderModel.fromJson(json['purchase_order'])
          : null,
      supplier: json['supplier'] != null
          ? Supplier.fromJson(json['supplier'])
          : null,
      site: json['site'] != null ? GRNSite.fromJson(json['site']) : null,
      creator: json['creator'] != null
          ? GRNCreator.fromJson(json['creator'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => GRNItem.fromJson(i)).toList()
          : null,
    );
  }
}

class GRNSite {
  final int id;
  final String? name;
  final String? address;
  final String? status;
  final String? startDate;
  final String? endDate;

  GRNSite({
    required this.id,
    this.name,
    this.address,
    this.status,
    this.startDate,
    this.endDate,
  });

  factory GRNSite.fromJson(Map<String, dynamic> json) {
    return GRNSite(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }
}

class GRNCreator {
  final int id;
  final String? name;
  final String? email;
  final String? avatar;

  GRNCreator({
    required this.id,
    this.name,
    this.email,
    this.avatar,
  });

  factory GRNCreator.fromJson(Map<String, dynamic> json) {
    return GRNCreator(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}

class GRNItem {
  final int id;
  final String? grnId;
  final String? poItemId;
  final String? materialId;
  final String? orderedQty;
  final String? receivedQty;
  final String? acceptedQty;
  final String? rejectedQty;
  final GRNMaterial? material;

  GRNItem({
    required this.id,
    this.grnId,
    this.poItemId,
    this.materialId,
    this.orderedQty,
    this.receivedQty,
    this.acceptedQty,
    this.rejectedQty,
    this.material,
  });

  factory GRNItem.fromJson(Map<String, dynamic> json) {
    return GRNItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      grnId: json['grn_id']?.toString(),
      poItemId: json['po_item_id']?.toString(),
      materialId: json['material_id']?.toString(),
      orderedQty: json['ordered_qty']?.toString(),
      receivedQty: json['received_qty']?.toString(),
      acceptedQty: json['accepted_qty']?.toString(),
      rejectedQty: json['rejected_qty']?.toString(),
      material: json['material'] != null
          ? GRNMaterial.fromJson(json['material'])
          : null,
    );
  }
}

class GRNMaterial {
  final int id;
  final String? name;
  final String? sku;
  final String? categoryId;
  final String? unitId;

  GRNMaterial({
    required this.id,
    this.name,
    this.sku,
    this.categoryId,
    this.unitId,
  });

  factory GRNMaterial.fromJson(Map<String, dynamic> json) {
    return GRNMaterial(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString(),
      sku: json['sku']?.toString(),
      categoryId: json['category_id']?.toString(),
      unitId: json['unit_id']?.toString(),
    );
  }
}
